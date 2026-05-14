// Auth routes connect /api/auth URLs to the auth controller.
const express = require('express');
const router = express.Router();

// Controller functions register users, log them in, and return current user.
const { register, login, getMe } = require('../controllers/authController');

// protect verifies the JWT token before private routes like /me.
const { protect } = require('../middleware/auth');

// Flutter RegisterScreen calls POST /api/auth/register.
router.post('/register', register);

// Flutter LoginScreen calls POST /api/auth/login.
router.post('/login', login);

// Flutter SplashScreen calls GET /api/auth/me to validate a saved token.
router.get('/me', protect, getMe);

// server.js mounts this router at /api/auth.
module.exports = router;
