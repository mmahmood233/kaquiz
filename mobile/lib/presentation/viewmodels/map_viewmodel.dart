// This ViewModel controls the map screen.
// It starts GPS sharing, sends location updates, and reloads friends' locations.
import 'dart:async';

// ChangeNotifier lets MapScreen rebuild when location data changes.
import 'package:flutter/foundation.dart';

// Position is the GPS object returned by geolocator.
import 'package:geolocator/geolocator.dart';

// LocationRepository talks to the backend; LocationService talks to the phone GPS.
import '../../data/repositories/location_repository.dart';
import '../../data/services/location_service.dart';
import '../../data/models/user_model.dart';

// The map uses this state to show loading, map content, or an error.
enum MapState { initial, loading, loaded, error }

// MapViewModel keeps the user's current location and friends' last locations.
class MapViewModel extends ChangeNotifier {
  final LocationRepository _locationRepository = LocationRepository();
  final LocationService _locationService = LocationService();

  // Private state used by the map screen.
  MapState _state = MapState.initial;
  String? _errorMessage;
  List<UserModel> _friendsWithLocations = [];
  Position? _currentPosition;
  Timer? _pollingTimer;
  bool _isInitialized = false;

  // Public read-only values used by MapScreen.
  MapState get state => _state;
  String? get errorMessage => _errorMessage;
  List<UserModel> get friendsWithLocations => _friendsWithLocations;
  Position? get currentPosition => _currentPosition;
  bool get isInitialized => _isInitialized;

  // Called when the home screen opens.
  // It gets the phone location, starts 5-second uploads, then loads friends.
  Future<void> initializeLocation() async {
    // If tracking already started, only refresh friends from the backend.
    if (_isInitialized) {
      await loadFriendsLocations();
      return;
    }

    _state = MapState.loading;
    notifyListeners();

    // First get this phone's GPS location so the map can center on the user.
    await loadCurrentLocation();

    // Only start the 5-second backend updates after GPS permission succeeds.
    if (_currentPosition != null) {
      _locationService.startLocationTracking(
        onPosition: (position) {
          // Each successful timer tick moves the user's marker on the map.
          _currentPosition = position;
          notifyListeners();
        },
      );
      _startFriendsPolling();
      _isInitialized = true;
    } else {
      _errorMessage = _locationService.lastError ?? 'Location unavailable.';
      _state = MapState.error;
      notifyListeners();
    }

    await loadFriendsLocations();
  }

  // Reads the phone location once without starting the repeating timer.
  Future<void> loadCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _currentPosition = position;
      notifyListeners();
    } else {
      _errorMessage = _locationService.lastError;
    }
  }

  // Calls the backend for friends that have a saved last known location.
  Future<void> loadFriendsLocations() async {
    if (_state != MapState.loading) {
      _state = MapState.loading;
      notifyListeners();
    }

    final response = await _locationRepository.getFriendsLocations();

    // Store friends with coordinates so MapScreen can create markers.
    if (response.success && response.data != null) {
      _friendsWithLocations = response.data!;
      _state = MapState.loaded;
    } else {
      _errorMessage = response.message;
      _state = MapState.error;
    }
    notifyListeners();
  }

  // Polls the backend every 10 seconds so friends' markers stay updated.
  void _startFriendsPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _silentRefreshFriends(),
    );
  }

  // Refreshes friend locations silently so the map does not flash a loader.
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

  // Stops GPS sharing and friend polling, usually when the user logs out.
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

  // Text used by the map status bar.
  String get trackingStatus {
    if (!_isInitialized) return 'Location sharing off';
    if (_locationService.isTracking) return 'Location sharing active';
    return 'Location sharing paused';
  }

  // Opens system settings when location permission was blocked.
  Future<void> openLocationPermissionSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  // Clean up timers when Provider removes this ViewModel.
  void dispose() {
    _locationService.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }
}
