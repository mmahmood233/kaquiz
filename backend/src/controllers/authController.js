// UserModel contains all database functions for users.
const User = require('../models/UserModel');

// generateToken creates a JWT token after login/register.
const { generateToken } = require('../utils/jwt');

// Simple email format check.
// It prevents obviously invalid emails before saving or logging in.
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Register a new user account.
exports.register = async (req, res, next) => {
  try {
    // Read email and password from the request body.
    const { email, password } = req.body;

    // Both email and password are required.
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password'
      });
    }

    // Trim spaces and store emails lowercase so duplicates are easier to detect.
    const normalizedEmail = email.trim().toLowerCase();

    // Stop registration if the email is not valid.
    if (!EMAIL_REGEX.test(normalizedEmail)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid email address'
      });
    }

    // Require a small minimum password length.
    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters'
      });
    }

    // Check if another user already registered with this email.
    const userExists = await User.findByEmail(normalizedEmail);

    if (userExists) {
      return res.status(400).json({
        success: false,
        message: 'An account already exists with this email'
      });
    }

    // Save the new user. The model hashes the password before inserting it.
    const user = await User.create(normalizedEmail, password);

    // Create a JWT token so the user is logged in immediately after registering.
    const token = generateToken(user.id);

    // Send back the token and safe user data.
    // Safe user data does not include the password.
    res.status(201).json({
      success: true,
      message: 'Account created successfully',
      data: {
        token,
        user: User.toSafeObject(user)
      }
    });
  } catch (error) {
    // Send unexpected errors to the shared Express error handler.
    next(error);
  }
};

// Login an existing user account.
exports.login = async (req, res, next) => {
  try {
    // Read login details from the request body.
    const { email, password } = req.body;

    // Both fields must be provided.
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password'
      });
    }

    // Use lowercase email so login works even if user typed capital letters.
    const normalizedEmail = email.trim().toLowerCase();

    // Find the user by email.
    const user = await User.findByEmail(normalizedEmail);

    // Do not say whether email or password was wrong.
    // This keeps the login response safer.
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Compare the typed password with the hashed password in the database.
    const isPasswordMatch = await User.matchPassword(user, password);

    if (!isPasswordMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Login succeeded, so create a fresh JWT token.
    const token = generateToken(user.id);

    // Return token and safe user profile.
    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: User.toSafeObject(user)
      }
    });
  } catch (error) {
    // Pass unexpected errors to the shared error handler.
    next(error);
  }
};

// Return the currently logged-in user's profile.
exports.getMe = async (req, res, next) => {
  try {
    // req.user is added by the auth middleware after it verifies the JWT token.
    const user = await User.findById(req.user.id);

    // Load the user's friends so the app can show profile/friend data after restart.
    const friends = await User.getFriends(req.user.id);

    // Return safe user data and safe friend data.
    res.status(200).json({
      success: true,
      data: {
        user: {
          ...User.toSafeObject(user),
          friends: friends.map(f => User.toSafeObject(f))
        }
      }
    });
  } catch (error) {
    // Pass unexpected errors to Express error middleware.
    next(error);
  }
};
