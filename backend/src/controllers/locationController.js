// UserModel contains location and friend database helpers.
const User = require('../models/UserModel');

// POST /api/locations
// Save the logged-in user's latest location.
exports.updateLocation = async (req, res, next) => {
  try {
    // Read latitude and longitude from the request body.
    const { latitude, longitude } = req.body;

    // Both coordinates are required.
    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({ success: false, message: 'Please provide latitude and longitude' });
    }

    // Convert values to numbers because JSON can send them as strings.
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);

    // Reject anything that cannot be parsed as a number.
    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({ success: false, message: 'Coordinates must be valid numbers' });
    }

    // Latitude must be between -90 and 90.
    // Longitude must be between -180 and 180.
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return res.status(400).json({ success: false, message: 'Coordinates out of valid range' });
    }

    // Save the valid location for the logged-in user.
    await User.updateLocation(req.user.id, lat, lng);

    // Return the saved location details.
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
    // Send unexpected errors to the global error handler.
    next(error);
  }
};

// GET /api/location/friends — Swagger-compatible friend locations endpoint
// Return the logged-in user's friends with their last known locations.
exports.getFriendsLocations = async (req, res, next) => {
  try {
    // Get all friends for the logged-in user.
    const friends = await User.getFriends(req.user.id);

    // Return safe friend objects, including location fields.
    res.status(200).json({
      success: true,
      data: {
        friends: friends.map(friend => User.toSafeObject(friend))
      }
    });
  } catch (error) {
    // Send unexpected errors to the global error handler.
    next(error);
  }
};
