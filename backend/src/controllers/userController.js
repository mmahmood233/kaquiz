const User = require('../models/UserModel');

// PUT /api/users — update name and/or avatar
exports.updateUser = async (req, res, next) => {
  try {
    const { name, avatar } = req.body;

    if (!name && !avatar) {
      return res.status(400).json({ success: false, message: 'Provide name or avatar to update' });
    }

    const user = await User.updateProfile(req.user.id, { name, avatar });

    res.status(200).json({
      id: user.id,
      name: user.name || user.email.split('@')[0],
      avatar: user.avatar || null,
      email: user.email
    });
  } catch (error) {
    next(error);
  }
};
