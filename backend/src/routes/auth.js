// Express router groups authentication routes.
const express = require('express');
const router = express.Router();

// Controller functions contain the actual auth logic.
const { register, login, getMe } = require('../controllers/authController');

// protect checks the JWT token before protected routes.
const { protect } = require('../middleware/auth');

// Create a new account.
router.post('/register', register);

// Login with email and password.
router.post('/login', login);

// Return current logged-in user. This route needs a valid token.
router.get('/me', protect, getMe);

// Export this router so server.js can mount it at /api/auth.
module.exports = router;
