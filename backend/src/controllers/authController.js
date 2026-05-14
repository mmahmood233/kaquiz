// Auth controller handles register, login, and "current user" requests.
// The Flutter auth screens call these routes through AuthRepository.
const User = require('../models/UserModel');

// generateToken creates the JWT token returned to Flutter after login/register.
const { generateToken } = require('../utils/jwt');

// Simple email format check before we query or save the user.
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// POST /api/auth/register
// Creates a new user, returns a token, and signs the app in immediately.
exports.register = async (req, res, next) => {
  try {
    // Flutter sends email and password in the JSON request body.
    const { email, password } = req.body;

    // Both fields are required to create an account.
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password'
      });
    }

    // Normalize email so AA@AA.AA and aa@aa.aa are treated as the same account.
    const normalizedEmail = email.trim().toLowerCase();

    // Stop early if the email clearly is not valid.
    if (!EMAIL_REGEX.test(normalizedEmail)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid email address'
      });
    }

    // Keep password validation simple for this project: minimum 6 characters.
    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters'
      });
    }

    // Do not allow duplicate accounts with the same email.
    const userExists = await User.findByEmail(normalizedEmail);

    if (userExists) {
      return res.status(400).json({
        success: false,
        message: 'An account already exists with this email'
      });
    }

    // UserModel hashes the password before inserting the new row in SQLite.
    const user = await User.create(normalizedEmail, password);

    // Create a token so Flutter can call protected routes right away.
    const token = generateToken(user.id);

    // Send token and safe user data. The password hash is never returned.
    res.status(201).json({
      success: true,
      message: 'Account created successfully',
      data: {
        token,
        user: User.toSafeObject(user)
      }
    });
  } catch (error) {
    // Unexpected errors go to the shared Express error handler.
    next(error);
  }
};

// POST /api/auth/login
// Checks email/password and returns a fresh JWT token when valid.
exports.login = async (req, res, next) => {
  try {
    // Flutter sends the typed email and password in JSON.
    const { email, password } = req.body;

    // Both fields are required to log in.
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password'
      });
    }

    // Lowercase email so login is not case-sensitive.
    const normalizedEmail = email.trim().toLowerCase();

    // Find the user account in SQLite.
    const user = await User.findByEmail(normalizedEmail);

    // Use one generic message so attackers cannot tell which field was wrong.
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Compare typed password with the stored bcrypt password hash.
    const isPasswordMatch = await User.matchPassword(user, password);

    if (!isPasswordMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Login succeeded, so create a fresh token for Flutter to store.
    const token = generateToken(user.id);

    // Return token and safe user profile without the password hash.
    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: User.toSafeObject(user)
      }
    });
  } catch (error) {
    // Unexpected errors go to the shared error handler.
    next(error);
  }
};

// GET /api/auth/me
// Flutter calls this on app start to check if the saved token still works.
exports.getMe = async (req, res, next) => {
  try {
    // auth middleware already verified the token and put the user on req.user.
    const user = await User.findById(req.user.id);

    // Include friends so Flutter can rebuild user state after app restart.
    const friends = await User.getFriends(req.user.id);

    // Return only safe user/friend fields. Never return password hashes.
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
    // Unexpected errors go to Express error middleware.
    next(error);
  }
};
