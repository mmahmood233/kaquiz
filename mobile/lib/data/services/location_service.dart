// Timer is used to send location every few seconds.
import 'dart:async';

// debugPrint writes useful location failures into the Flutter console.
import 'package:flutter/foundation.dart';

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

  // Last location/permission failure. The UI can show this to the user.
  String? _lastError;

  // Ask the device for current location.
  Future<Position?> getCurrentLocation() async {
    try {
      _lastError = null;

      // Location service must be enabled on the phone.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _lastError = 'Location services are turned off.';
        return null;
      }

      // Check and request location permission.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _lastError = 'Location permission was denied.';
          return null;
        }
      }

      // If permission is permanently denied, the app cannot get location.
      if (permission == LocationPermission.deniedForever) {
        _lastError =
            'Location permission is blocked. Enable it in iPhone Settings.';
        return null;
      }

      // Return a high-accuracy location reading.
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (e) {
      _lastError = 'Location update failed: $e';
      debugPrint('LOCATION UPDATE FAILURE: $e');
      // Return null if location fails for any reason.
      return null;
    }
  }

  // Start sending location immediately and then every 5 seconds.
  void startLocationTracking({void Function(Position position)? onPosition}) {
    if (_isTracking) return;

    _isTracking = true;
    _sendCurrentLocation(onPosition: onPosition);
    _locationTimer = Timer.periodic(
      const Duration(seconds: AppConstants.locationUpdateInterval),
      (_) => _sendCurrentLocation(onPosition: onPosition),
    );
  }

  // Get current location and send it to the backend.
  Future<void> _sendCurrentLocation({
    void Function(Position position)? onPosition,
  }) async {
    if (!_isTracking || _isSendingLocation) return;
    _isSendingLocation = true;
    final position = await getCurrentLocation();
    try {
      if (_isTracking && position != null) {
        onPosition?.call(position);
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
  String? get lastError => _lastError;

  // Clean up the timer when this service is destroyed.
  void dispose() {
    stopLocationTracking();
  }
}
