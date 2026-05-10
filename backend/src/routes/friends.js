const express = require('express');
const router = express.Router();
const { getFriends, deleteFriend, searchUsers } = require('../controllers/friendController');
const { protect } = require('../middleware/auth');

router.use(protect);

router.get('/search', searchUsers);
router.get('/', getFriends);
router.delete('/:id', deleteFriend);

module.exports = router;
