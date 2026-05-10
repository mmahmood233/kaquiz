const express = require('express');
const router = express.Router();
const {
  getFriends,
  deleteFriend,
  searchUsers,
  sendFriendRequest,
  getPendingFriendRequests,
  respondToFriendRequest
} = require('../controllers/friendController');
const { protect } = require('../middleware/auth');

router.use(protect);

router.get('/search', searchUsers);
router.post('/request', sendFriendRequest);
router.get('/requests', getPendingFriendRequests);
router.post('/respond', respondToFriendRequest);
router.get('/', getFriends);
router.delete('/:id', deleteFriend);

module.exports = router;
