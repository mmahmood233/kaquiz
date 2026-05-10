// Express router groups user profile routes.
const express = require('express');
const router = express.Router();

// Controller function for updating profile data.
const { updateUser } = require('../controllers/userController');

// User routes require the user to be logged in.
const { protect } = require('../middleware/auth');

// Apply auth protection to all routes below this line.
router.use(protect);

// Update the logged-in user's profile.
router.put('/', updateUser);

// Export this router so server.js can mount it at /api/users.
module.exports = router;
