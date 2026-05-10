// Timer is used to send location every few seconds.
import 'dart:async';

// geolocator reads device location and asks for location permission.
import 'package:geolocator/geolocator.dart';

// App constants and backend repository.
import '../../core/constants/app_constants.dart';
import '../repositories/location_repository.dart';

// LocationService owns permission checks, current location, and tracking timer.
class LocationService {
  // Repository used to send location to backend.
  final LocationRepository _locationRepository = LocationRepository();

  // Timer that repeats while the app is open/tracking.
  Timer? _locationTimer;

  // Whether location tracking is currently active.
  bool _isTracking = false;

  // Prevents two location sends from running at the same time.
  bool _isSendingLocation = false;

  // Ask the device for current location.
  Future<Position?> getCurrentLocation() async {
    try {
      // Location service must be enabled on the phone.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check and request location permission.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      // If permission is permanently denied, the app cannot get location.
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Return a high-accuracy location reading.
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      // Return null if location fails for any reason.
      return null;
    }
  }

  // Start sending location immediately and then every 5 seconds.
  void startLocationTracking() {
    if (_isTracking) return;

    _isTracking = true;
    _sendCurrentLocation();
    _locationTimer = Timer.periodic(
      const Duration(seconds: AppConstants.locationUpdateInterval),
      (_) => _sendCurrentLocation(),
    );
  }

  // Get current location and send it to the backend.
  Future<void> _sendCurrentLocation() async {
    if (!_isTracking || _isSendingLocation) return;
    _isSendingLocation = true;
    final position = await getCurrentLocation();
    try {
      if (_isTracking && position != null) {
        await _locationRepository.updateLocation(
          position.latitude,
          position.longitude,
        );
      }
    } finally {
      _isSendingLocation = false;
    }
  }

  // Stop the repeating location timer.
  void stopLocationTracking() {
    _isTracking = false;
    _isSendingLocation = false;
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  // Simple read-only tracking status.
  bool get isTracking => _isTracking;

  // Clean up the timer when this service is destroyed.
  void dispose() {
    stopLocationTracking();
  }
}
