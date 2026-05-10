const express = require('express');
const router = express.Router();
const { updateLocation } = require('../controllers/locationController');
const { protect } = require('../middleware/auth');

router.use(protect);
router.post('/', updateLocation);

module.exports = router;
