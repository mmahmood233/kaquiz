import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../repositories/location_repository.dart';

class LocationService {
  final LocationRepository _locationRepository = LocationRepository();
  Timer? _locationTimer;
  bool _isTracking = false;

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) return null;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
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
