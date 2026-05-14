// Friend controller supports the Swagger-style /api/friends routes.
// Some app screens use /api/invites, but these routes stay available too.
const User = require('../models/UserModel');

// db is used for invite-specific SQL that does not belong in UserModel.
const db = require('../config/database');

// GET /api/friends
// Returns all accepted friends for the logged-in user.
exports.getFriends = async (req, res, next) => {
  try {
    // req.user.id comes from the verified JWT token.
    const friends = await User.getFriends(req.user.id);

    // Convert SQLite rows into the user shape Flutter expects.
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

    // Send friends inside data.friends to match the mobile model parsing.
    res.status(200).json({
      success: true,
      data: {
        friends: data
      }
    });
  } catch (error) {
    // Unexpected errors go to the global error handler.
    next(error);
  }
};

// DELETE /api/friends/:id
// Removes an accepted friendship for both users.
exports.deleteFriend = async (req, res, next) => {
  try {
    // The friend ID comes from the URL path.
    const friendId = parseInt(req.params.id, 10);

    // Reject invalid IDs before running any SQL.
    if (isNaN(friendId)) {
      return res.status(400).json({ success: false, message: 'Invalid friend ID' });
    }

    // Make sure the logged-in user is actually friends with this ID.
    if (!await User.isFriend(req.user.id, friendId)) {
      return res.status(404).json({ success: false, message: 'Friend not found' });
    }

    // Remove both rows: me -> friend and friend -> me.
    await User.removeFriend(req.user.id, friendId);

    // Clear old invite history so either user can send a new request later.
    await db.run(
      'DELETE FROM invites WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      [req.user.id, friendId, friendId, req.user.id]
    );

    res.status(200).json({ success: true, message: 'Friend deleted successfully' });
  } catch (error) {
    next(error);
  }
};

// GET /api/friends/search?email=...
// Searches users that the logged-in user can still add.
exports.searchUsers = async (req, res, next) => {
  try {
    // Flutter can send ?email=abc or leave it empty to list all addable users.
    const { email } = req.query;
    const searchText = typeof email === 'string' ? email.trim() : '';

    // Exclude self, existing friends, and users with pending invites.
    const users = await User.searchByEmail(searchText, req.user.id);

    // Return public user data only, with no password fields.
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

// POST /api/friends/request
// Sends a friend request using receiverEmail in the request body.
exports.sendFriendRequest = async (req, res, next) => {
  try {
    // Swagger clients send the email of the user they want to add.
    const { receiverEmail } = req.body;

    // receiverEmail is required because this route searches by email.
    if (!receiverEmail || receiverEmail.trim().length < 1) {
      return res.status(400).json({ success: false, message: 'Please provide receiverEmail' });
    }

    // Find the account that should receive the request.
    const receiver = await User.findByEmail(receiverEmail.trim().toLowerCase());
    if (!receiver) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Users cannot send friend requests to themselves.
    if (req.user.id === receiver.id) {
      return res.status(400).json({ success: false, message: 'Cannot send request to yourself' });
    }

    // Existing friends do not need another request.
    if (await User.isFriend(req.user.id, receiver.id)) {
      return res.status(400).json({ success: false, message: 'Already friends with this user' });
    }

    // Check invites in both directions to prevent duplicate pending requests.
    const existingInvites = await db.all(
      'SELECT * FROM invites WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      [req.user.id, receiver.id, receiver.id, req.user.id]
    );

    if (existingInvites.length > 0) {
      // Pending means one of these users already sent a request.
      if (existingInvites.some(invite => invite.status === 'pending')) {
        return res.status(400).json({ success: false, message: 'A friend request is already pending' });
      }

      // Old accepted/denied invites are cleared so a new request can be sent.
      await db.run(
        'DELETE FROM invites WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
        [req.user.id, receiver.id, receiver.id, req.user.id]
      );
    }

    // Create the new pending invite row.
    const result = await db.run(
      'INSERT INTO invites (sender_id, receiver_id) VALUES (?, ?)',
      [req.user.id, receiver.id]
    );

    // Load the new invite row so the response can include its ID/status.
    const friendRequest = await db.get('SELECT * FROM invites WHERE id = ?', [result.lastID]);

    // Return a Swagger-friendly request object.
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
    // Unexpected errors go to the global error handler.
    next(error);
  }
};

// GET /api/friends/requests
// Returns incoming pending requests for the logged-in user.
exports.getPendingFriendRequests = async (req, res, next) => {
  try {
    // Join invites with users so each request includes sender profile data.
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

    // Format requests for the mobile app and Swagger contract.
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
    // Unexpected errors go to the global error handler.
    next(error);
  }
};

// POST /api/friends/respond
// Accepts or denies a pending request by requestId.
exports.respondToFriendRequest = async (req, res, next) => {
  try {
    // Client sends requestId and action: "accept", "deny", or "decline".
    const { requestId, action } = req.body;

    // Treat "decline" the same as "deny" for compatibility.
    const normalizedAction = action === 'decline' ? 'deny' : action;

    // requestId and a valid action are required.
    if (!requestId || !['accept', 'deny'].includes(normalizedAction)) {
      return res.status(400).json({ success: false, message: 'Please provide requestId and action accept or deny' });
    }

    // Only the receiver of a pending request is allowed to respond.
    const invite = await db.get(
      'SELECT * FROM invites WHERE id = ? AND receiver_id = ? AND status = ?',
      [requestId, req.user.id, 'pending']
    );

    // No matching pending invite means this request cannot be handled.
    if (!invite) {
      return res.status(404).json({ success: false, message: 'Friend request not found' });
    }

    // Accepting creates the friendship in both directions.
    if (normalizedAction === 'accept') {
      await User.addFriend(req.user.id, invite.sender_id);
      await db.run('UPDATE invites SET status = ? WHERE id = ?', ['accepted', invite.id]);
      return res.status(200).json({ success: true, message: 'Friend request accepted successfully' });
    }

    // Denying keeps the users separate and marks the request as denied.
    await db.run('UPDATE invites SET status = ? WHERE id = ?', ['denied', invite.id]);
    res.status(200).json({ success: true, message: 'Friend request denied successfully' });
  } catch (error) {
    // Unexpected errors go to the global error handler.
    next(error);
  }
};
