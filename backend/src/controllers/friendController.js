// UserModel contains database helper functions for users and friendships.
const User = require('../models/UserModel');

// db is the async SQLite helper used for custom invite queries.
const db = require('../config/database');

// GET /api/friends
// Return all friends for the logged-in user, including their last known location.
exports.getFriends = async (req, res, next) => {
  try {
    // req.user.id comes from the auth middleware.
    // It tells us which user's friends to load.
    const friends = await User.getFriends(req.user.id);

    // Convert database rows into the shape the mobile app expects.
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

    // Send the friends list back to the app.
    res.status(200).json({
      success: true,
      data: {
        friends: data
      }
    });
  } catch (error) {
    // Let the global error handler deal with unexpected errors.
    next(error);
  }
};

// DELETE /api/friends/:id
// Remove a friend from the logged-in user's friend list.
exports.deleteFriend = async (req, res, next) => {
  try {
    // The friend ID comes from the URL.
    const friendId = parseInt(req.params.id, 10);

    // Reject invalid IDs before touching the database.
    if (isNaN(friendId)) {
      return res.status(400).json({ success: false, message: 'Invalid friend ID' });
    }

    // Make sure this user is actually friends with that ID.
    if (!await User.isFriend(req.user.id, friendId)) {
      return res.status(404).json({ success: false, message: 'Friend not found' });
    }

    // Remove the friendship in both directions.
    await User.removeFriend(req.user.id, friendId);

    // Delete old invites between these two users so they can request again later.
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
// Search addable users by email, or return all addable users when email is empty.
exports.searchUsers = async (req, res, next) => {
  try {
    // Read the optional email search text from the query string.
    const { email } = req.query;
    const searchText = typeof email === 'string' ? email.trim() : '';

    // Search users but exclude the logged-in user from results.
    const users = await User.searchByEmail(searchText, req.user.id);

    // Return safe public user data only.
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
// Send a friend request using the receiver's email address.
exports.sendFriendRequest = async (req, res, next) => {
  try {
    // The frontend sends the email of the user it wants to add.
    const { receiverEmail } = req.body;

    // Receiver email is required.
    if (!receiverEmail || receiverEmail.trim().length < 1) {
      return res.status(400).json({ success: false, message: 'Please provide receiverEmail' });
    }

    // Find the user who should receive the request.
    const receiver = await User.findByEmail(receiverEmail.trim().toLowerCase());
    if (!receiver) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // A user cannot send a friend request to themselves.
    if (req.user.id === receiver.id) {
      return res.status(400).json({ success: false, message: 'Cannot send request to yourself' });
    }

    // If they are already friends, another request is not allowed.
    if (await User.isFriend(req.user.id, receiver.id)) {
      return res.status(400).json({ success: false, message: 'Already friends with this user' });
    }

    // Check for existing invites in either direction.
    // This prevents duplicate pending friend requests.
    const existingInvites = await db.all(
      'SELECT * FROM invites WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      [req.user.id, receiver.id, receiver.id, req.user.id]
    );

    if (existingInvites.length > 0) {
      // Pending means someone already sent a request, so stop here.
      if (existingInvites.some(invite => invite.status === 'pending')) {
        return res.status(400).json({ success: false, message: 'A friend request is already pending' });
      }

      // If old invites were accepted or denied, delete all of them so a fresh request can be created.
      await db.run(
        'DELETE FROM invites WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
        [req.user.id, receiver.id, receiver.id, req.user.id]
      );
    }

    // Create the new pending friend request.
    const result = await db.run(
      'INSERT INTO invites (sender_id, receiver_id) VALUES (?, ?)',
      [req.user.id, receiver.id]
    );

    // Load the created invite so we can return it in the response.
    const friendRequest = await db.get('SELECT * FROM invites WHERE id = ?', [result.lastID]);

    // Return the created request in the Swagger-friendly format.
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
    // Send unexpected errors to the global error handler.
    next(error);
  }
};

// GET /api/friends/requests — Swagger-compatible incoming pending requests
// Return pending friend requests sent to the logged-in user.
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
    // Send unexpected errors to the global error handler.
    next(error);
  }
};

// POST /api/friends/respond — Swagger-compatible accept/deny by request ID
// Accept or deny a pending friend request.
exports.respondToFriendRequest = async (req, res, next) => {
  try {
    // The app sends the request ID and the action to take.
    const { requestId, action } = req.body;

    // Accept both "deny" and "decline" so older clients still work.
    const normalizedAction = action === 'decline' ? 'deny' : action;

    // requestId and a valid action are required.
    if (!requestId || !['accept', 'deny'].includes(normalizedAction)) {
      return res.status(400).json({ success: false, message: 'Please provide requestId and action accept or deny' });
    }

    // Only the receiver of a pending request is allowed to respond to it.
    const invite = await db.get(
      'SELECT * FROM invites WHERE id = ? AND receiver_id = ? AND status = ?',
      [requestId, req.user.id, 'pending']
    );

    // If no matching pending invite exists, return not found.
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
    // Send unexpected errors to the global error handler.
    next(error);
  }
};
