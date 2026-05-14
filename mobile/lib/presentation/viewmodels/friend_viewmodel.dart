// This ViewModel connects friend screens to FriendRepository.
// Screens never call HTTP directly; they call this class instead.
import 'package:flutter/foundation.dart';

// FriendRepository contains the backend API calls for friends and invites.
import '../../data/repositories/friend_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/models/friend_request_model.dart';

// The UI reads this to show loading spinners, lists, or error states.
enum FriendState { initial, loading, loaded, error }

// FriendViewModel stores all friend-related data currently shown in the app.
class FriendViewModel extends ChangeNotifier {
  final FriendRepository _repo = FriendRepository();

  // Private lists keep search results, requests, and friends in memory.
  FriendState _state = FriendState.initial;
  String? _errorMessage;
  List<UserModel> _searchResults = [];
  List<FriendRequestModel> _pendingRequests = [];
  List<FriendRequestModel> _outgoingRequests = [];
  List<UserModel> _friends = [];
  bool _isSearchLoading = false;

  // Screens read these values and rebuild when notifyListeners is called.
  FriendState get state => _state;
  String? get errorMessage => _errorMessage;
  List<UserModel> get searchResults => _searchResults;
  List<FriendRequestModel> get pendingRequests => _pendingRequests;
  List<FriendRequestModel> get outgoingRequests => _outgoingRequests;
  List<UserModel> get friends => _friends;
  bool get isSearchLoading => _isSearchLoading;
  int get pendingRequestCount => _pendingRequests.length;

  // Called by SearchFriendsScreen.
  // Empty text loads all addable users; typed text filters by email on backend.
  Future<void> searchUsers(String email) async {
    _isSearchLoading = true;
    _errorMessage = null;
    notifyListeners();

    // The repository calls GET /api/friends/search and returns UserModel objects.
    final response = await _repo.searchUsers(email.trim());
    _isSearchLoading = false;
    if (response.success && response.data != null) {
      _searchResults = response.data!;
    } else {
      _errorMessage = response.message;
      _searchResults = [];
    }
    notifyListeners();
  }

  // Sends a request to the selected user from the search screen.
  // The repository calls POST /api/invites/{receiver_user_id}.
  Future<bool> sendFriendRequest(String receiverUserId) async {
    final response = await _repo.sendFriendRequest(receiverUserId);
    if (response.success) {
      await loadPendingRequests();
    } else {
      _errorMessage = response.message;
      notifyListeners();
    }
    return response.success;
  }

  // Loads requests for the Requests tab.
  // The backend returns both incoming and outgoing pending invites.
  Future<void> loadPendingRequests() async {
    _state = FriendState.loading;
    notifyListeners();

    final response = await _repo.getPendingRequests();
    if (response.success && response.data != null) {
      // Split the combined backend result into Received and Sent tabs.
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

  // Accepts or declines a request from the Requests tab.
  // After the backend responds, reload requests and friends so the UI is current.
  Future<bool> respondToRequest(String senderUserId, String action) async {
    final response = await _repo.respondToRequest(senderUserId, action);
    if (response.success) {
      // Accept changes the friends list; decline removes the pending request.
      await Future.wait([loadPendingRequests(), loadFriends()]);
    } else {
      _errorMessage = response.message;
      notifyListeners();
    }
    return response.success;
  }

  // Loads the Friends tab by calling GET /api/friends through the repository.
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

  // Deletes one friend.
  // The backend removes the friendship, then we reload friends and requests.
  Future<bool> deleteFriend(String friendId) async {
    final response = await _repo.deleteFriend(friendId);
    if (response.success) {
      await Future.wait([loadFriends(), loadPendingRequests()]);
    } else {
      _errorMessage = response.message;
      notifyListeners();
    }
    return response.success;
  }

  // Clears old search results so reopening search starts fresh.
  void clearSearchResults() {
    _searchResults = [];
    _errorMessage = null;
    notifyListeners();
  }

  // Clears friend data after logout so the next account does not see old data.
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
