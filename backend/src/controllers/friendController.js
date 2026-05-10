const User = require('../models/UserModel');
const db = require('../config/database');

// GET /api/friends — all friends with last known location
exports.getFriends = async (req, res, next) => {
  try {
    const friends = await User.getFriends(req.user.id);

    const data = friends.map(f => ({
        id: f.id,
        _id: String(f.id),
        name: f.name || f.email.split('@')[0],
        avatar: f.avatar || null,
        email: f.email,
        location: {
          latitude: f.latitude ?? null,
          longitude: f.longitude ?? null,
          lastUpdated: f.location_updated_at || null,
          timestamp: f.location_updated_at || null
        },
        createdAt: f.created_at
      }));

    res.status(200).json({
      success: true,
      data: {
        friends: data
      }
    });
  } catch (error) {
    next(error);
  }
};

// DELETE /api/friends/:id
exports.deleteFriend = async (req, res, next) => {
  try {
    const friendId = parseInt(req.params.id, 10);

    if (isNaN(friendId)) {
      return res.status(400).json({ success: false, message: 'Invalid friend ID' });
    }

    if (!await User.isFriend(req.user.id, friendId)) {
      return res.status(404).json({ success: false, message: 'Friend not found' });
    }

    await User.removeFriend(req.user.id, friendId);

    // Clean up invites in both directions
    await db.run(
      'DELETE FROM invites WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      [req.user.id, friendId, friendId, req.user.id]
    );

    res.status(200).json({ success: true, message: 'Friend deleted successfully' });
  } catch (error) {
    next(error);
  }
};

// GET /api/friends/search?email=... (extra — required by project brief)
exports.searchUsers = async (req, res, next) => {
  try {
    const { email } = req.query;

    if (!email || email.trim().length < 1) {
      return res.status(400).json({ success: false, message: 'Please provide email to search' });
    }

    const users = await User.searchByEmail(email.trim(), req.user.id);

    res.status(200).json({
      success: true,
      data: {
        users: users.map(u => User.toSafeObject(u))
      }
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/friends/request — Swagger-compatible request by email
exports.sendFriendRequest = async (req, res, next) => {
  try {
    const { receiverEmail } = req.body;

    if (!receiverEmail || receiverEmail.trim().length < 1) {
      return res.status(400).json({ success: false, message: 'Please provide receiverEmail' });
    }

    const receiver = await User.findByEmail(receiverEmail.trim().toLowerCase());
    if (!receiver) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (req.user.id === receiver.id) {
      return res.status(400).json({ success: false, message: 'Cannot send request to yourself' });
    }

    if (await User.isFriend(req.user.id, receiver.id)) {
      return res.status(400).json({ success: false, message: 'Already friends with this user' });
    }

    const existing = await db.get(
      'SELECT * FROM invites WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      [req.user.id, receiver.id, receiver.id, req.user.id]
    );

    if (existing) {
      if (existing.status === 'pending') {
        return res.status(400).json({ success: false, message: 'A friend request is already pending' });
      }
      await db.run('DELETE FROM invites WHERE id = ?', [existing.id]);
    }

    const result = await db.run(
      'INSERT INTO invites (sender_id, receiver_id) VALUES (?, ?)',
      [req.user.id, receiver.id]
    );

    const friendRequest = await db.get('SELECT * FROM invites WHERE id = ?', [result.lastID]);

    res.status(201).json({
      success: true,
      message: 'Friend request sent successfully',
      data: {
        friendRequest: {
          _id: String(friendRequest.id),
          id: friendRequest.id,
          sender: User.toSafeObject(req.user),
          receiver: User.toSafeObject(receiver),
          status: friendRequest.status,
          createdAt: friendRequest.created_at
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/friends/requests — Swagger-compatible incoming pending requests
exports.getPendingFriendRequests = async (req, res, next) => {
  try {
    const requests = await db.all(`
      SELECT i.id, i.status, i.created_at,
             s.id as sender_id, s.name as sender_name, s.avatar as sender_avatar, s.email as sender_email,
             s.latitude as sender_latitude, s.longitude as sender_longitude,
             s.location_updated_at as sender_location_updated_at, s.created_at as sender_created_at
      FROM invites i
      INNER JOIN users s ON i.sender_id = s.id
      WHERE i.receiver_id = ? AND i.status = 'pending'
      ORDER BY i.created_at DESC
    `, [req.user.id]);

    res.status(200).json({
      success: true,
      data: {
        requests: requests.map(r => ({
          _id: String(r.id),
          id: r.id,
          sender: User.toSafeObject({
            id: r.sender_id,
            name: r.sender_name,
            avatar: r.sender_avatar,
            email: r.sender_email,
            latitude: r.sender_latitude,
            longitude: r.sender_longitude,
            location_updated_at: r.sender_location_updated_at,
            created_at: r.sender_created_at
          }),
          receiver: User.toSafeObject(req.user),
          status: r.status,
          createdAt: r.created_at
        }))
      }
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/friends/respond — Swagger-compatible accept/deny by request ID
exports.respondToFriendRequest = async (req, res, next) => {
  try {
    const { requestId, action } = req.body;
    const normalizedAction = action === 'decline' ? 'deny' : action;

    if (!requestId || !['accept', 'deny'].includes(normalizedAction)) {
      return res.status(400).json({ success: false, message: 'Please provide requestId and action accept or deny' });
    }

    const invite = await db.get(
      'SELECT * FROM invites WHERE id = ? AND receiver_id = ? AND status = ?',
      [requestId, req.user.id, 'pending']
    );

    if (!invite) {
      return res.status(404).json({ success: false, message: 'Friend request not found' });
    }

    if (normalizedAction === 'accept') {
      await User.addFriend(req.user.id, invite.sender_id);
      await db.run('UPDATE invites SET status = ? WHERE id = ?', ['accepted', invite.id]);
      return res.status(200).json({ success: true, message: 'Friend request accepted successfully' });
    }

    await db.run('UPDATE invites SET status = ? WHERE id = ?', ['denied', invite.id]);
    res.status(200).json({ success: true, message: 'Friend request denied successfully' });
  } catch (error) {
    next(error);
  }
};
