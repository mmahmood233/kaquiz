const User = require('../models/UserModel');
const db = require('../config/database');

// GET /api/invites/:user_id — incoming + outgoing for current user
exports.getInvites = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const incoming = await db.all(`
      SELECT i.id, i.created_at,
             s.id as sender_id, s.name as sender_name, s.avatar as sender_avatar, s.email as sender_email
      FROM invites i
      INNER JOIN users s ON i.sender_id = s.id
      WHERE i.receiver_id = ? AND i.status = 'pending'
      ORDER BY i.created_at DESC
    `, [userId]);

    const outgoing = await db.all(`
      SELECT i.id, i.created_at,
             r.id as recipient_id, r.name as recipient_name, r.avatar as recipient_avatar, r.email as recipient_email
      FROM invites i
      INNER JOIN users r ON i.receiver_id = r.id
      WHERE i.sender_id = ? AND i.status = 'pending'
      ORDER BY i.created_at DESC
    `, [userId]);

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
    next(error);
  }
};

// POST /api/invites/:user_id — send invite to user_id
exports.sendInvite = async (req, res, next) => {
  try {
    const senderId = req.user.id;
    const receiverId = parseInt(req.params.user_id, 10);

    if (isNaN(receiverId)) {
      return res.status(400).json({ success: false, message: 'Invalid user ID' });
    }

    if (senderId === receiverId) {
      return res.status(400).json({ success: false, message: 'Cannot send invite to yourself' });
    }

    const receiver = await User.findById(receiverId);
    if (!receiver) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (await User.isFriend(senderId, receiverId)) {
      return res.status(400).json({ success: false, message: 'Already friends with this user' });
    }

    const existing = await db.get(
      'SELECT * FROM invites WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      [senderId, receiverId, receiverId, senderId]
    );

    if (existing) {
      if (existing.status === 'pending') {
        return res.status(400).json({ success: false, message: 'An invite is already pending' });
      }
      // Re-invite after decline is allowed
      await db.run('DELETE FROM invites WHERE id = ?', [existing.id]);
    }

    await db.run(
      'INSERT INTO invites (sender_id, receiver_id) VALUES (?, ?)',
      [senderId, receiverId]
    );

    res.status(200).json({ success: true, message: 'Invitation sent successfully' });
  } catch (error) {
    next(error);
  }
};

// POST /api/invites/:user_id/accept — accept invite FROM user_id
exports.acceptInvite = async (req, res, next) => {
  try {
    const receiverId = req.user.id;
    const senderId = parseInt(req.params.user_id, 10);

    if (isNaN(senderId)) {
      return res.status(400).json({ success: false, message: 'Invalid user ID' });
    }

    const invite = await db.get(
      'SELECT * FROM invites WHERE sender_id = ? AND receiver_id = ? AND status = ?',
      [senderId, receiverId, 'pending']
    );

    if (!invite) {
      return res.status(404).json({ success: false, message: 'Invitation not found' });
    }

    await User.addFriend(receiverId, senderId);
    await db.run('UPDATE invites SET status = ? WHERE id = ?', ['accepted', invite.id]);

    res.status(200).json({ success: true, message: 'Invitation accepted successfully' });
  } catch (error) {
    next(error);
  }
};

// POST /api/invites/:user_id/decline — decline invite FROM user_id
exports.declineInvite = async (req, res, next) => {
  try {
    const receiverId = req.user.id;
    const senderId = parseInt(req.params.user_id, 10);

    if (isNaN(senderId)) {
      return res.status(400).json({ success: false, message: 'Invalid user ID' });
    }

    const invite = await db.get(
      'SELECT * FROM invites WHERE sender_id = ? AND receiver_id = ? AND status = ?',
      [senderId, receiverId, 'pending']
    );

    if (!invite) {
      return res.status(404).json({ success: false, message: 'Invitation not found' });
    }

    await db.run('UPDATE invites SET status = ? WHERE id = ?', ['denied', invite.id]);

    res.status(200).json({ success: true, message: 'Invitation denied successfully' });
  } catch (error) {
    next(error);
  }
};
