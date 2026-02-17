import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../repositories/location_repository.dart';

class LocationService {
  final LocationRepository _locationRepository = LocationRepository();
  Timer? _locationTimer;
  bool _isTracking = false;

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
    } catch (e) {
      print('Location error: $e');
      return null;
    }
  }

  void startLocationTracking() {
    if (_isTracking) return;

    _isTracking = true;
    _locationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        final position = await getCurrentLocation();
        if (position != null) {
          await _locationRepository.updateLocation(
            position.latitude,
            position.longitude,
          );
        }
      },
    );
  }

  void stopLocationTracking() {
    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  bool get isTracking => _isTracking;

  void dispose() {
    stopLocationTracking();
  }
}
