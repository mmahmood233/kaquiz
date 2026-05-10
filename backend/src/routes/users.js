const express = require('express');
const router = express.Router();
const { updateUser } = require('../controllers/userController');
const { protect } = require('../middleware/auth');

router.use(protect);
router.put('/', updateUser);

module.exports = router;
