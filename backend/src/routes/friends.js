// Friend routes connect /api/friends URLs to friend controller functions.
const express = require('express');
const router = express.Router();

// Controller functions for searching users, requests, friend list, and deletion.
const {
  getFriends,
  deleteFriend,
  searchUsers,
  sendFriendRequest,
  getPendingFriendRequests,
  respondToFriendRequest
} = require('../controllers/friendController');

// Every friend route is private and requires a valid JWT token.
const { protect } = require('../middleware/auth');

// Apply auth protection to all routes below this line.
router.use(protect);

// GET /api/friends/search lists addable users or filters by ?email=.
router.get('/search', searchUsers);

// POST /api/friends/request sends a request by receiverEmail.
router.post('/request', sendFriendRequest);

// GET /api/friends/requests returns incoming pending requests.
router.get('/requests', getPendingFriendRequests);

// POST /api/friends/respond accepts or denies a pending request.
router.post('/respond', respondToFriendRequest);

// GET /api/friends returns the logged-in user's accepted friends.
router.get('/', getFriends);

// DELETE /api/friends/:id removes one accepted friend.
router.delete('/:id', deleteFriend);

// server.js mounts this router at /api/friends.
module.exports = router;
