// UserModel handles user and friendship database actions.
const User = require('../models/UserModel');

// db is used here for invite-specific SQL queries.
const db = require('../config/database');

// GET /api/invites/:user_id
// Return incoming and outgoing pending friend requests for the logged-in user.
exports.getInvites = async (req, res, next) => {
  try {
    // Always use req.user.id so users can only see their own invites.
    const userId = req.user.id;

    // Incoming requests are requests other people sent to this user.
    const incoming = await db.all(`
      SELECT i.id, i.created_at,
             s.id as sender_id, s.name as sender_name, s.avatar as sender_avatar, s.email as sender_email
      FROM invites i
      INNER JOIN users s ON i.sender_id = s.id
      WHERE i.receiver_id = ? AND i.status = 'pending'
      ORDER BY i.created_at DESC
    `, [userId]);

    // Outgoing requests are requests this user sent to other people.
    const outgoing = await db.all(`
      SELECT i.id, i.created_at,
             r.id as recipient_id, r.name as recipient_name, r.avatar as recipient_avatar, r.email as recipient_email
      FROM invites i
      INNER JOIN users r ON i.receiver_id = r.id
      WHERE i.sender_id = ? AND i.status = 'pending'
      ORDER BY i.created_at DESC
    `, [userId]);

    // Format the response so the app can show received and sent tabs.
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
    // Send unexpected errors to the global error handler.
    next(error);
  }
};

// POST /api/invites/:user_id
// Send a friend request by receiver user ID.
exports.sendInvite = async (req, res, next) => {
  try {
    // senderId is the logged-in user.
    const senderId = req.user.id;

    // receiverId comes from the URL.
    const receiverId = parseInt(req.params.user_id, 10);

    // The receiver ID must be a number.
    if (isNaN(receiverId)) {
      return res.status(400).json({ success: false, message: 'Invalid user ID' });
    }

    // Users cannot invite themselves.
    if (senderId === receiverId) {
      return res.status(400).json({ success: false, message: 'Cannot send invite to yourself' });
    }

    // Make sure the receiver exists.
    const receiver = await User.findById(receiverId);
    if (!receiver) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Do not allow a request if they are already friends.
    if (await User.isFriend(senderId, receiverId)) {
      return res.status(400).json({ success: false, message: 'Already friends with this user' });
    }

    // Find any invite between these two users in either direction.
    const existing = await db.get(
      'SELECT * FROM invites WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      [senderId, receiverId, receiverId, senderId]
    );

    if (existing) {
      // If it is still pending, do not create a duplicate request.
      if (existing.status === 'pending') {
        return res.status(400).json({ success: false, message: 'An invite is already pending' });
      }

      // If it was already handled before, remove it so a new request can be sent.
      await db.run('DELETE FROM invites WHERE id = ?', [existing.id]);
    }

    // Create the new pending invite.
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
// Accept a friend request from the user ID in the URL.
exports.acceptInvite = async (req, res, next) => {
  try {
    // receiverId is the logged-in user accepting the request.
    const receiverId = req.user.id;

    // senderId is the user who originally sent the request.
    const senderId = parseInt(req.params.user_id, 10);

    // The sender ID must be valid.
    if (isNaN(senderId)) {
      return res.status(400).json({ success: false, message: 'Invalid user ID' });
    }

    // Find a pending invite from sender to receiver.
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
// Deny a friend request from the user ID in the URL.
exports.declineInvite = async (req, res, next) => {
  try {
    // receiverId is the logged-in user denying the request.
    const receiverId = req.user.id;

    // senderId is the user who originally sent the request.
    const senderId = parseInt(req.params.user_id, 10);

    // The sender ID must be valid.
    if (isNaN(senderId)) {
      return res.status(400).json({ success: false, message: 'Invalid user ID' });
    }

    // Find a pending invite from sender to receiver.
    const invite = await db.get(
      'SELECT * FROM invites WHERE sender_id = ? AND receiver_id = ? AND status = ?',
      [senderId, receiverId, 'pending']
    );

    // If there is no pending invite, there is nothing to deny.
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
