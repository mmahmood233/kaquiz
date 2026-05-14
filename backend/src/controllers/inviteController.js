// Invite controller is the friend-request flow used by the Flutter app.
// It uses user IDs in the URL: /api/invites/:user_id.
const User = require('../models/UserModel');

// db runs invite-specific SQLite queries.
const db = require('../config/database');

// GET /api/invites/:user_id
// Returns incoming and outgoing pending friend requests.
exports.getInvites = async (req, res, next) => {
  try {
    // Ignore the URL user_id for security; use the logged-in user from JWT.
    const userId = req.user.id;

    // Incoming requests are requests other users sent to this account.
    const incoming = await db.all(`
      SELECT i.id, i.created_at,
             s.id as sender_id, s.name as sender_name, s.avatar as sender_avatar, s.email as sender_email
      FROM invites i
      INNER JOIN users s ON i.sender_id = s.id
      WHERE i.receiver_id = ? AND i.status = 'pending'
      ORDER BY i.created_at DESC
    `, [userId]);

    // Outgoing requests are requests this account sent to other users.
    const outgoing = await db.all(`
      SELECT i.id, i.created_at,
             r.id as recipient_id, r.name as recipient_name, r.avatar as recipient_avatar, r.email as recipient_email
      FROM invites i
      INNER JOIN users r ON i.receiver_id = r.id
      WHERE i.sender_id = ? AND i.status = 'pending'
      ORDER BY i.created_at DESC
    `, [userId]);

    // Flutter splits this response into Received and Sent tabs.
    res.status(200).json({
      success: true,
      data: {
        incoming: incoming.map(r => ({
          id: r.id,
          sender: {
            id: r.sender_id,
            name: r.sender_name || r.sender_email.split('@')[0],
            avatar: r.sender_avatar || null,
            email: r.sender_email
          },
          created_at: r.created_at
        })),
        outgoing: outgoing.map(r => ({
          id: r.id,
          recipient: {
            id: r.recipient_id,
            name: r.recipient_name || r.recipient_email.split('@')[0],
            avatar: r.recipient_avatar || null,
            email: r.recipient_email
          },
          created_at: r.created_at
        }))
      }
    });
  } catch (error) {
    // Unexpected errors go to the global error handler.
    next(error);
  }
};

// POST /api/invites/:user_id
// Sends a friend request to the receiver user ID in the URL.
exports.sendInvite = async (req, res, next) => {
  try {
    // senderId always comes from the verified JWT token.
    const senderId = req.user.id;

    // receiverId is the user being added from the Flutter search result.
    const receiverId = parseInt(req.params.user_id, 10);

    // The receiver ID must be a valid number before querying SQLite.
    if (isNaN(receiverId)) {
      return res.status(400).json({ success: false, message: 'Invalid user ID' });
    }

    // Users cannot invite themselves.
    if (senderId === receiverId) {
      return res.status(400).json({ success: false, message: 'Cannot send invite to yourself' });
    }

    // Make sure the selected user still exists.
    const receiver = await User.findById(receiverId);
    if (!receiver) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Existing friends do not need a new request.
    if (await User.isFriend(senderId, receiverId)) {
      return res.status(400).json({ success: false, message: 'Already friends with this user' });
    }

    // Check both directions so duplicate pending requests cannot happen.
    const existingInvites = await db.all(
      'SELECT * FROM invites WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      [senderId, receiverId, receiverId, senderId]
    );

    if (existingInvites.length > 0) {
      // If any request is still pending, stop here.
      if (existingInvites.some(invite => invite.status === 'pending')) {
        return res.status(400).json({ success: false, message: 'An invite is already pending' });
      }

      // Old accepted/denied invites are removed so users can reconnect later.
      await db.run(
        'DELETE FROM invites WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
        [senderId, receiverId, receiverId, senderId]
      );
    }

    // Create the new pending invite row.
    await db.run(
      'INSERT INTO invites (sender_id, receiver_id) VALUES (?, ?)',
      [senderId, receiverId]
    );

    res.status(200).json({ success: true, message: 'Invitation sent successfully' });
  } catch (error) {
    next(error);
  }
};

// POST /api/invites/:user_id/accept
// Accepts a pending friend request from the sender ID in the URL.
exports.acceptInvite = async (req, res, next) => {
  try {
    // receiverId is the logged-in user accepting the request.
    const receiverId = req.user.id;

    // senderId is the user who originally sent the request.
    const senderId = parseInt(req.params.user_id, 10);

    // The sender ID must be valid before querying SQLite.
    if (isNaN(senderId)) {
      return res.status(400).json({ success: false, message: 'Invalid user ID' });
    }

    // Only accept a request that is pending and sent to this logged-in user.
    const invite = await db.get(
      'SELECT * FROM invites WHERE sender_id = ? AND receiver_id = ? AND status = ?',
      [senderId, receiverId, 'pending']
    );

    // If there is no pending invite, there is nothing to accept.
    if (!invite) {
      return res.status(404).json({ success: false, message: 'Invitation not found' });
    }

    // Add both users as friends and mark the invite accepted.
    await User.addFriend(receiverId, senderId);
    await db.run('UPDATE invites SET status = ? WHERE id = ?', ['accepted', invite.id]);

    res.status(200).json({ success: true, message: 'Invitation accepted successfully' });
  } catch (error) {
    next(error);
  }
};

// POST /api/invites/:user_id/decline
// Declines a pending friend request from the sender ID in the URL.
exports.declineInvite = async (req, res, next) => {
  try {
    // receiverId is the logged-in user declining the request.
    const receiverId = req.user.id;

    // senderId is the user who originally sent the request.
    const senderId = parseInt(req.params.user_id, 10);

    // The sender ID must be valid before querying SQLite.
    if (isNaN(senderId)) {
      return res.status(400).json({ success: false, message: 'Invalid user ID' });
    }

    // Only decline a request that is pending and sent to this logged-in user.
    const invite = await db.get(
      'SELECT * FROM invites WHERE sender_id = ? AND receiver_id = ? AND status = ?',
      [senderId, receiverId, 'pending']
    );

    // If there is no pending invite, there is nothing to decline.
    if (!invite) {
      return res.status(404).json({ success: false, message: 'Invitation not found' });
    }

    // Mark the invite denied. This does not create a friendship.
    await db.run('UPDATE invites SET status = ? WHERE id = ?', ['denied', invite.id]);

    res.status(200).json({ success: true, message: 'Invitation denied successfully' });
  } catch (error) {
    next(error);
  }
};
