import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/services/location_service.dart';
import '../../data/models/user_model.dart';

enum MapState { initial, loading, loaded, error }

class MapViewModel extends ChangeNotifier {
  final LocationRepository _locationRepository = LocationRepository();
  final LocationService _locationService = LocationService();

  MapState _state = MapState.initial;
  String? _errorMessage;
  List<UserModel> _friendsWithLocations = [];
  Position? _currentPosition;

  MapState get state => _state;
  String? get errorMessage => _errorMessage;
  List<UserModel> get friendsWithLocations => _friendsWithLocations;
  Position? get currentPosition => _currentPosition;
  LocationService get locationService => _locationService;

  Future<void> initializeLocation() async {
    final hasPermission = await _locationService.checkLocationPermission();
    if (!hasPermission) {
      final granted = await _locationService.requestLocationPermission();
      if (!granted) {
        _errorMessage = 'Location permission denied';
        _state = MapState.error;
        notifyListeners();
        return;
      }
    }

    await loadCurrentLocation();
    _locationService.startLocationTracking();
  }

  Future<void> loadCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _currentPosition = position;
      notifyListeners();
    }
  }

  Future<void> loadFriendsLocations() async {
    _state = MapState.loading;
    notifyListeners();

    final response = await _locationRepository.getFriendsLocations();

    if (response.success && response.data != null) {
      _friendsWithLocations = response.data!;
      _state = MapState.loaded;
    } else {
      _errorMessage = response.message;
      _state = MapState.error;
    }
    notifyListeners();
  }

  void stopTracking() {
    _locationService.stopLocationTracking();
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}
