// verifyToken checks whether a JWT token is valid and not expired.
const { verifyToken } = require('../utils/jwt');

// UserModel loads the user account connected to the token.
const User = require('../models/UserModel');

// protect runs before routes that require login.
// Flutter sends Authorization: Bearer <token>, and this middleware verifies it.
const protect = async (req, res, next) => {
  // Start with no token, then read it from the Authorization header if present.
  let token;

  // Expected header format from Flutter: Authorization: Bearer <token>
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  // No token means the request is not logged in, so stop before the controller.
  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Not authorized to access this route'
    });
  }

  try {
    // Decode and verify the JWT token using JWT_SECRET.
    const decoded = verifyToken(token);
    
    // Invalid or expired tokens are rejected.
    if (!decoded) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token'
      });
    }

    // Load the user from SQLite and attach it to req.user.
    // Controllers use req.user.id instead of trusting IDs from the client.
    req.user = await User.findById(decoded.id);
    
    // If the token points to a deleted/missing user, reject it.
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'User not found'
      });
    }

    // Token is valid, so continue to the protected controller.
    next();
  } catch (error) {
    // Any auth failure returns the same unauthorized response.
    return res.status(401).json({
      success: false,
      message: 'Not authorized to access this route'
    });
  }
};

// Route files import this to protect private API endpoints.
module.exports = { protect };
