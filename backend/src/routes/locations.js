// Express router groups location routes.
const express = require('express');
const router = express.Router();

// Controller functions for updating and reading locations.
const { updateLocation, getFriendsLocations } = require('../controllers/locationController');

// Location routes require the user to be logged in.
const { protect } = require('../middleware/auth');

// Apply auth protection to all routes below this line.
router.use(protect);

// Update current user's location.
router.post('/', updateLocation);

// Swagger-compatible update route.
router.post('/update', updateLocation);

// Get friends with their last known locations.
router.get('/friends', getFriendsLocations);

// Export this router so server.js can mount it.
module.exports = router;
