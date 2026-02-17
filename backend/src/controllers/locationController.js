const User = require('../models/UserModel');

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

    const user = await User.updateLocation(req.user.id, latitude, longitude);

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
    const friends = await User.getFriends(req.user.id);
    const friendsWithLocations = friends.filter(friend => 
      friend.latitude !== null && 
      friend.longitude !== null
    );

    res.status(200).json({
      success: true,
      data: {
        friends: friendsWithLocations.map(f => User.toSafeObject(f))
      }
    });
  } catch (error) {
    next(error);
  }
};
