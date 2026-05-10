// Express router groups invite routes used by the Flutter app.
const express = require('express');
const router = express.Router();

// Controller functions for invite actions.
const { getInvites, sendInvite, acceptInvite, declineInvite } = require('../controllers/inviteController');

// Every invite route requires the user to be logged in.
const { protect } = require('../middleware/auth');

// Apply auth protection to all routes below this line.
router.use(protect);

// Get incoming and outgoing pending invites.
router.get('/:user_id', getInvites);

// Send an invite to a user ID.
router.post('/:user_id', sendInvite);

// Accept an invite from a user ID.
router.post('/:user_id/accept', acceptInvite);

// Decline an invite from a user ID.
router.post('/:user_id/decline', declineInvite);

// Export this router so server.js can mount it at /api/invites.
module.exports = router;
