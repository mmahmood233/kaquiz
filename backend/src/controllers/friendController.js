const User = require('../models/UserModel');
const db = require('../config/database');

// GET /api/friends — all friends with last known location
exports.getFriends = async (req, res, next) => {
  try {
    const friends = await User.getFriends(req.user.id);

    res.status(200).json(
      friends.map(f => ({
        id: f.id,
        name: f.name || f.email.split('@')[0],
        avatar: f.avatar || null,
        email: f.email,
        location: {
          latitude: f.latitude ? String(f.latitude) : null,
          longitude: f.longitude ? String(f.longitude) : null,
          timestamp: f.location_updated_at || null
        }
      }))
    );
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
