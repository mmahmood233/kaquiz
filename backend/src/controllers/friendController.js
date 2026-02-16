const User = require('../models/User');
const FriendRequest = require('../models/FriendRequest');

exports.searchUsers = async (req, res, next) => {
  try {
    const { email } = req.query;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email to search'
      });
    }

    const users = await User.find({
      email: { $regex: email, $options: 'i' },
      _id: { $ne: req.user._id }
    }).select('email location');

    res.status(200).json({
      success: true,
      data: {
        users
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

    const receiver = await User.findOne({ email: receiverEmail });

    if (!receiver) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    if (req.user.friends.includes(receiver._id)) {
      return res.status(400).json({
        success: false,
        message: 'Already friends with this user'
      });
    }

    const existingRequest = await FriendRequest.findOne({
      $or: [
        { sender: req.user._id, receiver: receiver._id },
        { sender: receiver._id, receiver: req.user._id }
      ]
    });

    if (existingRequest) {
      return res.status(400).json({
        success: false,
        message: 'Friend request already exists'
      });
    }

    const friendRequest = await FriendRequest.create({
      sender: req.user._id,
      receiver: receiver._id
    });

    const populatedRequest = await FriendRequest.findById(friendRequest._id)
      .populate('sender', 'email')
      .populate('receiver', 'email');

    res.status(201).json({
      success: true,
      message: 'Friend request sent successfully',
      data: {
        friendRequest: populatedRequest
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.getPendingRequests = async (req, res, next) => {
  try {
    const requests = await FriendRequest.find({
      receiver: req.user._id,
      status: 'pending'
    }).populate('sender', 'email location');

    res.status(200).json({
      success: true,
      data: {
        requests
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

    const friendRequest = await FriendRequest.findOne({
      _id: requestId,
      receiver: req.user._id,
      status: 'pending'
    });

    if (!friendRequest) {
      return res.status(404).json({
        success: false,
        message: 'Friend request not found'
      });
    }

    if (action === 'accept') {
      await User.findByIdAndUpdate(req.user._id, {
        $addToSet: { friends: friendRequest.sender }
      });

      await User.findByIdAndUpdate(friendRequest.sender, {
        $addToSet: { friends: req.user._id }
      });

      friendRequest.status = 'accepted';
    } else {
      friendRequest.status = 'denied';
    }

    await friendRequest.save();

    res.status(200).json({
      success: true,
      message: `Friend request ${action}ed successfully`,
      data: {
        friendRequest
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.getFriends = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id).populate('friends', 'email location');

    res.status(200).json({
      success: true,
      data: {
        friends: user.friends
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

    const user = await User.findById(req.user._id);

    if (!user.friends.includes(friendId)) {
      return res.status(400).json({
        success: false,
        message: 'User is not in your friends list'
      });
    }

    await User.findByIdAndUpdate(req.user._id, {
      $pull: { friends: friendId }
    });

    await User.findByIdAndUpdate(friendId, {
      $pull: { friends: req.user._id }
    });

    res.status(200).json({
      success: true,
      message: 'Friend removed successfully'
    });
  } catch (error) {
    next(error);
  }
};
