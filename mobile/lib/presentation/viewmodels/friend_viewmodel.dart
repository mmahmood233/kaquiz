import 'package:flutter/foundation.dart';
import '../../data/repositories/friend_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/models/friend_request_model.dart';

enum FriendState { initial, loading, loaded, error }

class FriendViewModel extends ChangeNotifier {
  final FriendRepository _friendRepository = FriendRepository();

  FriendState _state = FriendState.initial;
  String? _errorMessage;
  List<UserModel> _searchResults = [];
  List<FriendRequestModel> _pendingRequests = [];
  List<UserModel> _friends = [];

  FriendState get state => _state;
  String? get errorMessage => _errorMessage;
  List<UserModel> get searchResults => _searchResults;
  List<FriendRequestModel> get pendingRequests => _pendingRequests;
  List<UserModel> get friends => _friends;

  Future<void> searchUsers(String email) async {
    if (email.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _state = FriendState.loading;
    notifyListeners();

    final response = await _friendRepository.searchUsers(email);

    if (response.success && response.data != null) {
      _searchResults = response.data!;
      _state = FriendState.loaded;
    } else {
      _errorMessage = response.message;
      _state = FriendState.error;
    }
    notifyListeners();
  }

  Future<bool> sendFriendRequest(String receiverEmail) async {
    final response = await _friendRepository.sendFriendRequest(receiverEmail);
    
    if (!response.success) {
      _errorMessage = response.message;
      notifyListeners();
    }
    
    return response.success;
  }

  Future<void> loadPendingRequests() async {
    _state = FriendState.loading;
    notifyListeners();

    final response = await _friendRepository.getPendingRequests();

    if (response.success && response.data != null) {
      _pendingRequests = response.data!;
      _state = FriendState.loaded;
    } else {
      _errorMessage = response.message;
      _state = FriendState.error;
    }
    notifyListeners();
  }

  Future<bool> respondToRequest(String requestId, String action) async {
    final response = await _friendRepository.respondToRequest(requestId, action);
    
    if (response.success) {
      await loadPendingRequests();
      await loadFriends();
    } else {
      _errorMessage = response.message;
      notifyListeners();
    }
    
    return response.success;
  }

  Future<void> loadFriends() async {
    _state = FriendState.loading;
    notifyListeners();

    final response = await _friendRepository.getFriends();

    if (response.success && response.data != null) {
      _friends = response.data!;
      _state = FriendState.loaded;
    } else {
      _errorMessage = response.message;
      _state = FriendState.error;
    }
    notifyListeners();
  }

  Future<bool> deleteFriend(String friendId) async {
    final response = await _friendRepository.deleteFriend(friendId);
    
    if (response.success) {
      await loadFriends();
    } else {
      _errorMessage = response.message;
      notifyListeners();
    }
    
    return response.success;
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }
}
