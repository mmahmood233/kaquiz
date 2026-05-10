// ChangeNotifier lets friend screens rebuild when state changes.
import 'package:flutter/foundation.dart';

// Repository and models for friend data.
import '../../data/repositories/friend_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/models/friend_request_model.dart';

// Loading states used by friend screens.
enum FriendState { initial, loading, loaded, error }

// FriendViewModel stores friends, search results, and friend requests.
class FriendViewModel extends ChangeNotifier {
  final FriendRepository _repo = FriendRepository();

  // Private state values.
  FriendState _state = FriendState.initial;
  String? _errorMessage;
  List<UserModel> _searchResults = [];
  List<FriendRequestModel> _pendingRequests = [];
  List<FriendRequestModel> _outgoingRequests = [];
  List<UserModel> _friends = [];
  bool _isSearchLoading = false;

  // Public read-only state values for widgets.
  FriendState get state => _state;
  String? get errorMessage => _errorMessage;
  List<UserModel> get searchResults => _searchResults;
  List<FriendRequestModel> get pendingRequests => _pendingRequests;
  List<FriendRequestModel> get outgoingRequests => _outgoingRequests;
  List<UserModel> get friends => _friends;
  bool get isSearchLoading => _isSearchLoading;
  int get pendingRequestCount => _pendingRequests.length;

  // Search for users by email.
  Future<void> searchUsers(String email) async {
    // Empty search clears results.
    if (email.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isSearchLoading = true;
    notifyListeners();

    // Ask repository/backend for matching users.
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

  // Send a friend request using the searched user's ID.
  Future<bool> sendFriendRequest(String receiverUserId) async {
    final response = await _repo.sendFriendRequest(receiverUserId);
    if (!response.success) {
      _errorMessage = response.message;
      notifyListeners();
    }
    return response.success;
  }

  // Load incoming and outgoing pending requests.
  Future<void> loadPendingRequests() async {
    _state = FriendState.loading;
    notifyListeners();

    final response = await _repo.getPendingRequests();
    if (response.success && response.data != null) {
      // Split combined repository data into UI tabs.
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

  // Accept or deny an incoming friend request.
  Future<bool> respondToRequest(String senderUserId, String action) async {
    final response = await _repo.respondToRequest(senderUserId, action);
    if (response.success) {
      // Refresh requests and friends after accepting or denying.
      await Future.wait([loadPendingRequests(), loadFriends()]);
    } else {
      _errorMessage = response.message;
      notifyListeners();
    }
    return response.success;
  }

  // Load the user's current friends list.
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

  // Delete one friend by ID.
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

  // Clear search when leaving the search screen.
  void clearSearchResults() {
    _searchResults = [];
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all friend-related data on logout.
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
