// verifyToken checks if a JWT token is valid.
const { verifyToken } = require('../utils/jwt');

// UserModel is used to load the user connected to the token.
const User = require('../models/UserModel');

// protect is middleware for routes that require login.
const protect = async (req, res, next) => {
  // The token will be read from the Authorization header.
  let token;

  // Expected header format: Authorization: Bearer <token>
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  // If there is no token, the user is not logged in.
  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Not authorized to access this route'
    });
  }

  try {
    // Decode and verify the JWT token.
    const decoded = verifyToken(token);
    
    // If the token is invalid or expired, reject the request.
    if (!decoded) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token'
      });
    }

    // Load the user from the database and attach it to req.user.
    // Controllers can then use req.user.id.
    req.user = await User.findById(decoded.id);
    
    // If the token points to a user that no longer exists, reject it.
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'User not found'
      });
    }

    // Continue to the controller.
    next();
  } catch (error) {
    // Any auth error is returned as unauthorized.
    return res.status(401).json({
      success: false,
      message: 'Not authorized to access this route'
    });
  }
};

// Export the middleware so route files can use it.
module.exports = { protect };
