import 'package:flutter/foundation.dart';
import '../../data/repositories/friend_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/models/friend_request_model.dart';

enum FriendState { initial, loading, loaded, error }

class FriendViewModel extends ChangeNotifier {
  final FriendRepository _repo = FriendRepository();

  FriendState _state = FriendState.initial;
  String? _errorMessage;
  List<UserModel> _searchResults = [];
  List<FriendRequestModel> _pendingRequests = [];
  List<FriendRequestModel> _outgoingRequests = [];
  List<UserModel> _friends = [];
  bool _isSearchLoading = false;

  FriendState get state => _state;
  String? get errorMessage => _errorMessage;
  List<UserModel> get searchResults => _searchResults;
  List<FriendRequestModel> get pendingRequests => _pendingRequests;
  List<FriendRequestModel> get outgoingRequests => _outgoingRequests;
  List<UserModel> get friends => _friends;
  bool get isSearchLoading => _isSearchLoading;
  int get pendingRequestCount => _pendingRequests.length;

  Future<void> searchUsers(String email) async {
    if (email.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isSearchLoading = true;
    notifyListeners();

    final response = await _repo.searchUsers(email);
    _isSearchLoading = false;
    if (response.success && response.data != null) {
      _searchResults = response.data!;
    } else {
      _errorMessage = response.message;
      _searchResults = [];
    }
    notifyListeners();
  }

  // Sends invite using user's ID (from search result)
  Future<bool> sendFriendRequest(String receiverUserId) async {
    final response = await _repo.sendFriendRequest(receiverUserId);
    if (!response.success) {
      _errorMessage = response.message;
      notifyListeners();
    }
    return response.success;
  }

  Future<void> loadPendingRequests() async {
    _state = FriendState.loading;
    notifyListeners();

    final response = await _repo.getPendingRequests();
    if (response.success && response.data != null) {
      _pendingRequests = response.data!.where((r) => r.isIncoming).toList();
      _outgoingRequests = response.data!.where((r) => !r.isIncoming).toList();
      _state = FriendState.loaded;
    } else {
      _errorMessage = response.message;
      _state = FriendState.error;
      _pendingRequests = [];
      _outgoingRequests = [];
    }
    notifyListeners();
  }

  // action: 'accept' | 'deny'  — senderUserId is the ID of the person who sent the invite
  Future<bool> respondToRequest(String senderUserId, String action) async {
    final response = await _repo.respondToRequest(senderUserId, action);
    if (response.success) {
      await Future.wait([loadPendingRequests(), loadFriends()]);
    } else {
      _errorMessage = response.message;
      notifyListeners();
    }
    return response.success;
  }

  Future<void> loadFriends() async {
    _state = FriendState.loading;
    notifyListeners();

    final response = await _repo.getFriends();
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
    final response = await _repo.deleteFriend(friendId);
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
    _errorMessage = null;
    notifyListeners();
  }

  void clearSessionData() {
    _state = FriendState.initial;
    _errorMessage = null;
    _searchResults = [];
    _pendingRequests = [];
    _outgoingRequests = [];
    _friends = [];
    _isSearchLoading = false;
    notifyListeners();
  }
}
