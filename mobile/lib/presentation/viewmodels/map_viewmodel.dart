import 'dart:async';
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
  Timer? _pollingTimer;
  bool _isInitialized = false;

  MapState get state => _state;
  String? get errorMessage => _errorMessage;
  List<UserModel> get friendsWithLocations => _friendsWithLocations;
  Position? get currentPosition => _currentPosition;
  bool get isInitialized => _isInitialized;

  Future<void> initializeLocation() async {
    if (_isInitialized) {
      await loadFriendsLocations();
      return;
    }

    _state = MapState.loading;
    notifyListeners();

    await loadCurrentLocation();

    if (_currentPosition != null) {
      _locationService.startLocationTracking();
      _startFriendsPolling();
      _isInitialized = true;
    }

    await loadFriendsLocations();
  }

  Future<void> loadCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _currentPosition = position;
      notifyListeners();
    }
  }

  Future<void> loadFriendsLocations() async {
    if (_state != MapState.loading) {
      _state = MapState.loading;
      notifyListeners();
    }

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

  void _startFriendsPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _silentRefreshFriends(),
    );
  }

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

  void stopTracking() {
    _locationService.stopLocationTracking();
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isInitialized = false;
  }

  String get trackingStatus {
    if (!_isInitialized) return 'Not tracking';
    if (_locationService.isTracking) return 'Tracking active';
    return 'Tracking paused';
  }

  @override
  void dispose() {
    _locationService.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }
}
