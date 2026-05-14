// This service reads the phone's GPS location and sends it to the backend.
// The timer keeps doing this every few seconds while the app is open.
import 'dart:async';

// debugPrint shows location failures in the Flutter/Xcode console.
import 'package:flutter/foundation.dart';

// geolocator asks for permission and reads the device's current position.
import 'package:geolocator/geolocator.dart';

// AppConstants has the 5-second interval, and LocationRepository calls backend.
import '../../core/constants/app_constants.dart';
import '../repositories/location_repository.dart';

// LocationService owns permission checks, GPS reading, and repeated uploading.
class LocationService {
  // This repository calls POST /api/locations after we get GPS coordinates.
  final LocationRepository _locationRepository = LocationRepository();

  // This timer fires every 5 seconds while location sharing is active.
  Timer? _locationTimer;

  // Prevents starting multiple timers for the same logged-in user.
  bool _isTracking = false;

  // Avoids overlapping location requests if GPS is slow.
  bool _isSendingLocation = false;

  // Stores the last permission/GPS error so the map screen can explain it.
  String? _lastError;

  // Asks iOS/Android for the current location after checking permission.
  Future<Position?> getCurrentLocation() async {
    try {
      _lastError = null;

      // The phone's global Location Services switch must be on first.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _lastError = 'Location services are turned off.';
        return null;
      }

      // If the app does not have permission yet, show the system prompt.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _lastError = 'Location permission was denied.';
          return null;
        }
      }

      // If the user blocked permission, they must enable it in Settings.
      if (permission == LocationPermission.deniedForever) {
        _lastError =
            'Location permission is blocked. Enable it in iPhone Settings.';
        return null;
      }

      // High accuracy gives better map markers when the device supports it.
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (e) {
      _lastError = 'Location update failed: $e';
      debugPrint('LOCATION UPDATE FAILURE: $e');
      // Returning null tells the ViewModel to show a location error instead.
      return null;
    }
  }

  // Starts location sharing now, then repeats every 5 seconds.
  // onPosition updates the map marker as soon as a new GPS point is found.
  void startLocationTracking({void Function(Position position)? onPosition}) {
    if (_isTracking) return;

    _isTracking = true;
    _sendCurrentLocation(onPosition: onPosition);
    _locationTimer = Timer.periodic(
      const Duration(seconds: AppConstants.locationUpdateInterval),
      (_) => _sendCurrentLocation(onPosition: onPosition),
    );
  }

  // Reads the GPS position and calls the backend to save it as "last known".
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

  // Stops background timers when the user logs out or the service is disposed.
  void stopLocationTracking() {
    _isTracking = false;
    _isSendingLocation = false;
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  // Read-only values used by the ViewModel/UI.
  bool get isTracking => _isTracking;
  String? get lastError => _lastError;

  // Clean up the timer when this service is destroyed.
  void dispose() {
    stopLocationTracking();
  }
}
