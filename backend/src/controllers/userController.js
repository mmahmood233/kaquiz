// User controller handles profile updates from the Flutter profile screen.
const User = require('../models/UserModel');

// PUT /api/users
// Updates the logged-in user's display name and/or avatar.
exports.updateUser = async (req, res, next) => {
  try {
    // Flutter sends the fields it wants to change in the JSON body.
    const { name, avatar } = req.body;

    // At least one editable profile field must be sent.
    if (!name && !avatar) {
      return res.status(400).json({ success: false, message: 'Provide name or avatar to update' });
    }

    // Use req.user.id from the auth middleware, not an ID from the client.
    const user = await User.updateProfile(req.user.id, { name, avatar });

    // Return the updated safe user object so Flutter can refresh immediately.
    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: User.toSafeObject(user)
      }
    });
  } catch (error) {
    // Unexpected errors go to the global error handler.
    next(error);
  }
};
