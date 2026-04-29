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

    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);

    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude must be valid numbers'
      });
    }

    if (lat < -90 || lat > 90) {
      return res.status(400).json({
        success: false,
        message: 'Latitude must be between -90 and 90'
      });
    }

    if (lng < -180 || lng > 180) {
      return res.status(400).json({
        success: false,
        message: 'Longitude must be between -180 and 180'
      });
    }

    const user = await User.updateLocation(req.user.id, lat, lng);
    const safeUser = User.toSafeObject(user);

    res.status(200).json({
      success: true,
      message: 'Location updated successfully',
      data: {
        location: safeUser.location
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
      friend.longitude !== null &&
      friend.latitude !== undefined &&
      friend.longitude !== undefined
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
