const express = require('express');
const router = express.Router();
const { updateLocation, getFriendsLocations } = require('../controllers/locationController');
const { protect } = require('../middleware/auth');

router.use(protect);

router.post('/update', updateLocation);
router.get('/friends', getFriendsLocations);

module.exports = router;
