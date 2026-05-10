import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_constants.dart';
import '../repositories/location_repository.dart';

class LocationService {
  final LocationRepository _locationRepository = LocationRepository();
  Timer? _locationTimer;
  bool _isTracking = false;
  bool _isSendingLocation = false;

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  void startLocationTracking() {
    if (_isTracking) return;

    _isTracking = true;
    _sendCurrentLocation();
    _locationTimer = Timer.periodic(
      const Duration(seconds: AppConstants.locationUpdateInterval),
      (_) => _sendCurrentLocation(),
    );
  }

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

  void stopLocationTracking() {
    _isTracking = false;
    _isSendingLocation = false;
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  bool get isTracking => _isTracking;

  void dispose() {
    stopLocationTracking();
  }
}
