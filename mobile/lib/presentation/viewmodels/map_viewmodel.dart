// Timer is used to refresh friend locations.
import 'dart:async';

// ChangeNotifier lets the map screen rebuild on state changes.
import 'package:flutter/foundation.dart';

// Position is the device location object from geolocator.
import 'package:geolocator/geolocator.dart';

// Backend repository, device location service, and user model.
import '../../data/repositories/location_repository.dart';
import '../../data/services/location_service.dart';
import '../../data/models/user_model.dart';

// Loading states used by the map screen.
enum MapState { initial, loading, loaded, error }

// MapViewModel manages current location, friend locations, and timers.
class MapViewModel extends ChangeNotifier {
  final LocationRepository _locationRepository = LocationRepository();
  final LocationService _locationService = LocationService();

  // Private state values.
  MapState _state = MapState.initial;
  String? _errorMessage;
  List<UserModel> _friendsWithLocations = [];
  Position? _currentPosition;
  Timer? _pollingTimer;
  bool _isInitialized = false;

  // Public read-only values for the UI.
  MapState get state => _state;
  String? get errorMessage => _errorMessage;
  List<UserModel> get friendsWithLocations => _friendsWithLocations;
  Position? get currentPosition => _currentPosition;
  bool get isInitialized => _isInitialized;

  // Start location tracking and load friend locations.
  Future<void> initializeLocation() async {
    // If already initialized, just refresh friend locations.
    if (_isInitialized) {
      await loadFriendsLocations();
      return;
    }

    _state = MapState.loading;
    notifyListeners();

    // First get this device's current location.
    await loadCurrentLocation();

    // Start periodic location updates only if current location is available.
    if (_currentPosition != null) {
      _locationService.startLocationTracking();
      _startFriendsPolling();
      _isInitialized = true;
    }

    await loadFriendsLocations();
  }

  // Load current device location once.
  Future<void> loadCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _currentPosition = position;
      notifyListeners();
    }
  }

  // Load friends who have location data.
  Future<void> loadFriendsLocations() async {
    if (_state != MapState.loading) {
      _state = MapState.loading;
      notifyListeners();
    }

    final response = await _locationRepository.getFriendsLocations();

    // Store locations or show an error.
    if (response.success && response.data != null) {
      _friendsWithLocations = response.data!;
      _state = MapState.loaded;
    } else {
      _errorMessage = response.message;
      _state = MapState.error;
    }
    notifyListeners();
  }

  // Refresh friend locations every 10 seconds while map is open.
  void _startFriendsPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _silentRefreshFriends(),
    );
  }

  // Refresh friend locations without showing a loading spinner.
  Future<void> _silentRefreshFriends() async {
    final response = await _locationRepository.getFriendsLocations();
    if (response.success && response.data != null) {
      _friendsWithLocations = response.data!;
      if (_state != MapState.loading) {
        _state = MapState.loaded;
      }
      notifyListeners();
    }
  }

  // Stop timers and clear map data, usually on logout.
  void stopTracking() {
    _locationService.stopLocationTracking();
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isInitialized = false;
    _currentPosition = null;
    _friendsWithLocations = [];
    _state = MapState.initial;
    _errorMessage = null;
    notifyListeners();
  }

  // Human-readable tracking status for UI.
  String get trackingStatus {
    if (!_isInitialized) return 'Not tracking';
    if (_locationService.isTracking) return 'Tracking active';
    return 'Tracking paused';
  }

  @override
  // Clean up timers when provider is destroyed.
  void dispose() {
    _locationService.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }
}
