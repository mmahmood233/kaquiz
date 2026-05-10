// Express router groups friend routes.
const express = require('express');
const router = express.Router();

// Controller functions for searching, requests, friend list, and deletion.
const {
  getFriends,
  deleteFriend,
  searchUsers,
  sendFriendRequest,
  getPendingFriendRequests,
  respondToFriendRequest
} = require('../controllers/friendController');

// Every friend route requires the user to be logged in.
const { protect } = require('../middleware/auth');

// Apply auth protection to all routes below this line.
router.use(protect);

// Search users by email.
router.get('/search', searchUsers);

// Send a friend request by receiver email.
router.post('/request', sendFriendRequest);

// Get incoming pending friend requests.
router.get('/requests', getPendingFriendRequests);

// Accept or deny a friend request.
router.post('/respond', respondToFriendRequest);

// Get all friends.
router.get('/', getFriends);

// Delete one friend by ID.
router.delete('/:id', deleteFriend);

// Export this router so server.js can mount it at /api/friends.
module.exports = router;
