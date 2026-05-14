// Location controller saves my location and returns friends' last locations.
// Flutter calls these routes from LocationRepository and MapViewModel.
const User = require('../models/UserModel');

// POST /api/locations
// Saves the logged-in user's latest GPS coordinates.
exports.updateLocation = async (req, res, next) => {
  try {
    // Flutter sends latitude and longitude every 5 seconds while the app is open.
    const { latitude, longitude } = req.body;

    // Both coordinates are required to update last known location.
    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({ success: false, message: 'Please provide latitude and longitude' });
    }

    // Convert values to numbers because JSON body values may arrive as strings.
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);

    // Reject values that are not real numbers.
    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({ success: false, message: 'Coordinates must be valid numbers' });
    }

    // Check valid earth coordinate ranges before writing to SQLite.
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return res.status(400).json({ success: false, message: 'Coordinates out of valid range' });
    }

    // Save the valid location on the current user's row.
    await User.updateLocation(req.user.id, lat, lng);

    // Return the saved location details so Flutter knows the update worked.
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
    // Unexpected errors go to the global error handler.
    next(error);
  }
};

// GET /api/location/friends and GET /api/locations/friends
// Returns the logged-in user's friends with their last saved locations.
exports.getFriendsLocations = async (req, res, next) => {
  try {
    // Only return friends of req.user, so users cannot see strangers' locations.
    const friends = await User.getFriends(req.user.id);

    // Safe friend objects include location fields but never password hashes.
    res.status(200).json({
      success: true,
      data: {
        friends: friends.map(friend => User.toSafeObject(friend))
      }
    });
  } catch (error) {
    // Unexpected errors go to the global error handler.
    next(error);
  }
};
