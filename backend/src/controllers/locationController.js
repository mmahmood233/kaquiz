const User = require('../models/User');

exports.updateLocation = async (req, res, next) => {
  try {
    const { latitude, longitude } = req.body;

    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Please provide latitude and longitude'
      });
    }

    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return res.status(400).json({
        success: false,
        message: 'Invalid coordinates'
      });
    }

    const user = await User.findByIdAndUpdate(
      req.user._id,
      {
        location: {
          latitude,
          longitude,
          lastUpdated: new Date()
        }
      },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: 'Location updated successfully',
      data: {
        location: user.location
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.getFriendsLocations = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id).populate('friends', 'email location');

    const friendsWithLocations = user.friends.filter(friend => 
      friend.location && 
      friend.location.latitude !== null && 
      friend.location.longitude !== null
    );

    res.status(200).json({
      success: true,
      data: {
        friends: friendsWithLocations
      }
    });
  } catch (error) {
    next(error);
  }
};
