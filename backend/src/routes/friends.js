const express = require('express');
const router = express.Router();
const {
  searchUsers,
  sendFriendRequest,
  getPendingRequests,
  respondToRequest,
  getFriends,
  deleteFriend
} = require('../controllers/friendController');
const { protect } = require('../middleware/auth');

router.use(protect);

router.get('/search', searchUsers);
router.post('/request', sendFriendRequest);
router.get('/requests', getPendingRequests);
router.post('/respond', respondToRequest);
router.get('/', getFriends);
router.delete('/:friendId', deleteFriend);

module.exports = router;
