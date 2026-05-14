// Invite routes are the main friend-request routes used by the Flutter app.
const express = require('express');
const router = express.Router();

// Controller functions load, send, accept, and decline invites.
const { getInvites, sendInvite, acceptInvite, declineInvite } = require('../controllers/inviteController');

// Every invite route requires a valid JWT token.
const { protect } = require('../middleware/auth');

// Apply auth protection to all routes below this line.
router.use(protect);

// GET /api/invites/:user_id returns incoming and outgoing pending invites.
router.get('/:user_id', getInvites);

// POST /api/invites/:user_id sends an invite to that user ID.
router.post('/:user_id', sendInvite);

// POST /api/invites/:user_id/accept accepts an invite from that user ID.
router.post('/:user_id/accept', acceptInvite);

// POST /api/invites/:user_id/decline declines an invite from that user ID.
router.post('/:user_id/decline', declineInvite);

// server.js mounts this router at /api/invites.
module.exports = router;
