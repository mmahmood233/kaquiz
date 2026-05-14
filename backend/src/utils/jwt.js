// jsonwebtoken creates and checks login tokens for protected API routes.
const jwt = require('jsonwebtoken');

// Create a token that stores the user's database ID.
// Flutter saves this token and sends it with protected requests.
const generateToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE
  });
};

// Verify a token and return decoded data, usually { id: userId }.
// Invalid or expired tokens return null so auth middleware can reject them.
const verifyToken = (token) => {
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    return null;
  }
};

// Controllers create tokens; middleware verifies tokens.
module.exports = {
  generateToken,
  verifyToken
};
