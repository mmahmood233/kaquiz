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
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: User.toSafeObject(user)
      }
    });
  } catch (error) {
    next(error);
  }
};
