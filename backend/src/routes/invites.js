const express = require('express');
const router = express.Router();
const { getInvites, sendInvite, acceptInvite, declineInvite } = require('../controllers/inviteController');
const { protect } = require('../middleware/auth');

router.use(protect);

router.get('/:user_id', getInvites);
router.post('/:user_id', sendInvite);
router.post('/:user_id/accept', acceptInvite);
router.post('/:user_id/decline', declineInvite);

module.exports = router;
