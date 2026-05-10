const User = require('../models/UserModel');

// POST /api/locations
exports.updateLocation = async (req, res, next) => {
  try {
    const { latitude, longitude } = req.body;

    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({ success: false, message: 'Please provide latitude and longitude' });
    }

    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);

    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({ success: false, message: 'Coordinates must be valid numbers' });
    }

    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return res.status(400).json({ success: false, message: 'Coordinates out of valid range' });
    }

    await User.updateLocation(req.user.id, lat, lng);

    res.status(200).json({
      success: true,
      message: 'Location updated successfully',
      data: {
        location: {
          latitude: lat,
          longitude: lng,
          lastUpdated: new Date().toISOString()
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/location/friends — Swagger-compatible friend locations endpoint
exports.getFriendsLocations = async (req, res, next) => {
  try {
    const friends = await User.getFriends(req.user.id);

    res.status(200).json({
      success: true,
      data: {
        friends: friends.map(friend => User.toSafeObject(friend))
      }
    });
  } catch (error) {
    next(error);
  }
};
