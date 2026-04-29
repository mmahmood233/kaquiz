const User = require('../models/UserModel');
const FriendRequest = require('../models/FriendRequestModel');
const db = require('../config/database');

exports.searchUsers = async (req, res, next) => {
  try {
    const { email } = req.query;

    if (!email || email.trim().length < 1) {
      return res.status(400).json({
        success: false,
        message: 'Please provide an email to search'
      });
    }

    const users = await User.searchByEmail(email.trim(), req.user.id);

    res.status(200).json({
      success: true,
      data: {
        users: users.map(u => User.toSafeObject(u))
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.sendFriendRequest = async (req, res, next) => {
  try {
    const { receiverEmail } = req.body;

    if (!receiverEmail) {
      return res.status(400).json({
        success: false,
        message: 'Please provide receiver email'
      });
    }

    const normalizedEmail = receiverEmail.trim().toLowerCase();

    if (normalizedEmail === req.user.email.toLowerCase()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot send friend request to yourself'
      });
    }

    const receiver = await User.findByEmail(normalizedEmail);

    if (!receiver) {
      return res.status(404).json({
        success: false,
        message: 'User not found with that email'
      });
    }

    if (await User.isFriend(req.user.id, receiver.id)) {
      return res.status(400).json({
        success: false,
        message: 'You are already friends with this user'
      });
    }

    const existingRequest = await FriendRequest.findByUsers(req.user.id, receiver.id);

    if (existingRequest) {
      if (existingRequest.status === 'pending') {
        return res.status(400).json({
          success: false,
          message: 'A friend request is already pending'
        });
      }
      // Allow re-sending if previously denied
      await db.run('DELETE FROM friend_requests WHERE id = ?', [existingRequest.id]);
    }

    const friendRequest = await FriendRequest.create(req.user.id, receiver.id);
    const populatedRequest = await FriendRequest.findWithUsers(friendRequest.id);

    res.status(201).json({
      success: true,
      message: 'Friend request sent successfully',
      data: {
        friendRequest: FriendRequest.formatWithUsers(populatedRequest)
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.getPendingRequests = async (req, res, next) => {
  try {
    const requests = await FriendRequest.getPendingForUser(req.user.id);

    res.status(200).json({
      success: true,
      data: {
        requests: requests.map(r => FriendRequest.formatWithUsers(r))
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.respondToRequest = async (req, res, next) => {
  try {
    const { requestId, action } = req.body;

    if (!requestId || !action) {
      return res.status(400).json({
        success: false,
        message: 'Please provide requestId and action'
      });
    }

    if (!['accept', 'deny'].includes(action)) {
      return res.status(400).json({
        success: false,
        message: 'Action must be either accept or deny'
      });
    }

    const friendRequest = await FriendRequest.findById(requestId);

    if (!friendRequest) {
      return res.status(404).json({
        success: false,
        message: 'Friend request not found'
      });
    }

    if (friendRequest.receiver_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to respond to this request'
      });
    }

    if (friendRequest.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'This friend request has already been responded to'
      });
    }

    if (action === 'accept') {
      await User.addFriend(req.user.id, friendRequest.sender_id);
      await FriendRequest.updateStatus(requestId, 'accepted');
    } else {
      await FriendRequest.updateStatus(requestId, 'denied');
    }

    const updatedRequest = await FriendRequest.findById(requestId);

    res.status(200).json({
      success: true,
      message: action === 'accept'
        ? 'Friend request accepted'
        : 'Friend request denied',
      data: {
        status: updatedRequest ? updatedRequest.status : action === 'accept' ? 'accepted' : 'denied'
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.getFriends = async (req, res, next) => {
  try {
    const friends = await User.getFriends(req.user.id);

    res.status(200).json({
      success: true,
      data: {
        friends: friends.map(f => User.toSafeObject(f))
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.deleteFriend = async (req, res, next) => {
  try {
    const { friendId } = req.params;
    const friendIdInt = parseInt(friendId, 10);

    if (!friendId || isNaN(friendIdInt)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid friendId'
      });
    }

    if (!await User.isFriend(req.user.id, friendIdInt)) {
      return res.status(400).json({
        success: false,
        message: 'This user is not in your friends list'
      });
    }

    await User.removeFriend(req.user.id, friendIdInt);

    // Clean up all friend_requests between these two users in both directions
    await db.run(
      'DELETE FROM friend_requests WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      [req.user.id, friendIdInt, friendIdInt, req.user.id]
    );

    res.status(200).json({
      success: true,
      message: 'Friend removed successfully'
    });
  } catch (error) {
    next(error);
  }
};
