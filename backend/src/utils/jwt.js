// jsonwebtoken creates and checks login tokens.
const jwt = require('jsonwebtoken');

// Create a token that stores the user's ID.
const generateToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE
  });
};

// Verify a token and return its decoded data.
// If the token is invalid or expired, return null.
const verifyToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    return null;
  }
};

// Export token helpers for controllers and middleware.
module.exports = {
  generateToken,
  verifyToken
};
