// Location routes connect map/location API URLs to controller functions.
const express = require('express');
const router = express.Router();

// Controller functions save my location and read friends' saved locations.
const { updateLocation, getFriendsLocations } = require('../controllers/locationController');

// Location routes are private because location data belongs to logged-in users.
const { protect } = require('../middleware/auth');

// Apply auth protection to all routes below this line.
router.use(protect);

// POST /api/locations saves the current user's latitude/longitude.
router.post('/', updateLocation);

// POST /api/locations/update is kept for Swagger/API compatibility.
router.post('/update', updateLocation);

// GET /api/location/friends returns friends with their last known locations.
router.get('/friends', getFriendsLocations);

// server.js mounts this router at both /api/locations and /api/location.
module.exports = router;
