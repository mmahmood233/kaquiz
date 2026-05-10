// UserModel contains profile update database logic.
const User = require('../models/UserModel');

// PUT /api/users — update name and/or avatar
// Update the logged-in user's profile details.
exports.updateUser = async (req, res, next) => {
  try {
    // The app can update display name and avatar.
    const { name, avatar } = req.body;

    // At least one field must be sent.
    if (!name && !avatar) {
      return res.status(400).json({ success: false, message: 'Provide name or avatar to update' });
    }

    // Save the profile change for the logged-in user.
    const user = await User.updateProfile(req.user.id, { name, avatar });

    // Return the updated safe user object.
    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: User.toSafeObject(user)
      }
    });
  } catch (error) {
    // Send unexpected errors to the global error handler.
    next(error);
  }
};
