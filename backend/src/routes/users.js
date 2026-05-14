// User routes connect profile API URLs to the user controller.
const express = require('express');
const router = express.Router();

// Controller function updates profile data such as display name.
const { updateUser } = require('../controllers/userController');

// User profile routes require a valid JWT token.
const { protect } = require('../middleware/auth');

// Apply auth protection to all routes below this line.
router.use(protect);

// Flutter ProfileScreen calls PUT /api/users to save display name.
router.put('/', updateUser);

// server.js mounts this router at /api/users.
module.exports = router;
