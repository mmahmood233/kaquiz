const User = require('../models/UserModel');
const FriendRequest = require('../models/FriendRequestModel');
const db = require('../config/database');

exports.searchUsers = async (req, res, next) => {
  try {
    const { email } = req.query;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email to search'
      });
    }

    const users = await User.searchByEmail(email, req.user.id);

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

    if (receiverEmail === req.user.email) {
      return res.status(400).json({
        success: false,
        message: 'Cannot send friend request to yourself'
      });
    }

    const receiver = await User.findByEmail(receiverEmail);

    if (!receiver) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    if (await User.isFriend(req.user.id, receiver.id)) {
      return res.status(400).json({
        success: false,
        message: 'Already friends with this user'
      });
    }

    const existingRequest = await FriendRequest.findByUsers(req.user.id, receiver.id);

    if (existingRequest) {
      return res.status(400).json({
        success: false,
        message: 'Friend request already exists'
      });
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

    if (!friendRequest || friendRequest.receiver_id !== req.user.id || friendRequest.status !== 'pending') {
      return res.status(404).json({
        success: false,
        message: 'Friend request not found'
      });
    }

    if (action === 'accept') {
      await User.addFriend(req.user.id, friendRequest.sender_id);
      await FriendRequest.updateStatus(requestId, 'accepted');
    } else {
      await FriendRequest.updateStatus(requestId, 'denied');
    }

    res.status(200).json({
      success: true,
      message: `Friend request ${action}ed successfully`,
      data: {
        friendRequest: FriendRequest.findById(requestId)
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

    if (!friendId) {
      return res.status(400).json({
        success: false,
        message: 'Please provide friendId'
      });
    }

    if (!await User.isFriend(req.user.id, friendId)) {
      return res.status(400).json({
        success: false,
        message: 'User is not in your friends list'
      });
    }

    await User.removeFriend(req.user.id, friendId);
    
    // Delete the friend request so they can send a new one later
    const existingRequest = await FriendRequest.findByUsers(req.user.id, friendId);
    if (existingRequest) {
      await db.run('DELETE FROM friend_requests WHERE id = ?', [existingRequest.id]);
    }

    res.status(200).json({
      success: true,
      message: 'Friend removed successfully'
    });
  } catch (error) {
    next(error);
  }
};
