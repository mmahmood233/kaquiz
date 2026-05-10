// JSON helpers for backend request and response bodies.
import 'dart:convert';

// HTTP client for backend calls.
import 'package:http/http.dart' as http;

// API paths and token storage.
import '../../core/constants/api_constants.dart';
import '../../core/utils/secure_storage.dart';

// Data models used by friend features.
import '../models/user_model.dart';
import '../models/friend_request_model.dart';
import '../models/api_response.dart';

// Maximum time to wait for friend API calls.
const _timeout = Duration(seconds: 10);

// FriendRepository handles search, requests, friends, and deletion API calls.
class FriendRepository {
  // Build headers for authenticated JSON requests.
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Read current user ID from secure storage.
  Future<String?> _getUserId() => SecureStorage.getUserId();

  // Search users by email.
  Future<ApiResponse<List<UserModel>>> searchUsers(String email) async {
    try {
      // Send the search text as a query parameter.
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.searchUsers}?email=${Uri.encodeComponent(email)}'),
            headers: headers,
          )
          .timeout(_timeout);

      // Convert backend users into UserModel objects.
      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> usersJson = json['data']['users'];
        return ApiResponse(
            success: true,
            data: usersJson.map((j) => UserModel.fromJson(j)).toList());
      }
      return ApiResponse(
          success: false, message: json['message'] ?? 'Search failed');
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Send a friend request by receiver user ID.
  Future<ApiResponse<void>> sendFriendRequest(String receiverUserId) async {
    try {
      // The backend uses /invites/:user_id for this app flow.
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.sendInvite(receiverUserId)}'),
            headers: headers,
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: json['message']);
      }
      return ApiResponse(
          success: false, message: json['message'] ?? 'Failed to send invite');
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Load incoming and outgoing pending friend requests.
  Future<ApiResponse<List<FriendRequestModel>>> getPendingRequests() async {
    try {
      // The invite endpoint needs the current user ID.
      final userId = await _getUserId();
      if (userId == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      // Ask backend for both received and sent requests.
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.getInvites(userId)}'),
            headers: headers,
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final data = json['data'] ?? json;
        final List incoming = data['incoming'] ?? [];
        final List outgoing = data['outgoing'] ?? [];

        // Mark each request as incoming or outgoing for the UI tabs.
        final requests = [
          ...incoming.map((j) => FriendRequestModel.fromIncoming(j)),
          ...outgoing.map((j) => FriendRequestModel.fromOutgoing(j)),
        ];
        return ApiResponse(success: true, data: requests);
      }
      return ApiResponse(
          success: false,
          message: json['message'] ?? 'Failed to get invites');
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Accept a friend request from a sender user ID.
  Future<ApiResponse<void>> acceptInvite(String senderUserId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.acceptInvite(senderUserId)}'),
            headers: headers,
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: json['message']);
      }
      return ApiResponse(
          success: false,
          message: json['message'] ?? 'Failed to accept invite');
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Decline a friend request from a sender user ID.
  Future<ApiResponse<void>> declineInvite(String senderUserId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.declineInvite(senderUserId)}'),
            headers: headers,
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: json['message']);
      }
      return ApiResponse(
          success: false,
          message: json['message'] ?? 'Failed to decline invite');
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // One helper used by the ViewModel for both accept and deny actions.
  Future<ApiResponse<void>> respondToRequest(
      String senderUserId, String action) async {
    if (action == 'accept') return acceptInvite(senderUserId);
    return declineInvite(senderUserId);
  }

  // Load the logged-in user's friends.
  Future<ApiResponse<List<UserModel>>> getFriends() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getFriends}'),
            headers: headers,
          )
          .timeout(_timeout);

      final dynamic json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Supports both old plain-array responses and current data.friends responses.
        final List<dynamic> friendsJson =
            json is List ? json : (json['data']?['friends'] ?? []);
        return ApiResponse(
            success: true,
            data: friendsJson.map((j) => UserModel.fromJson(j)).toList());
      }
      final msg = json is Map ? json['message'] : 'Failed to get friends';
      return ApiResponse(success: false, message: msg ?? 'Failed to get friends');
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Delete a friend by user ID.
  Future<ApiResponse<void>> deleteFriend(String friendId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.deleteFriend(friendId)}'),
            headers: headers,
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: json['message']);
      }
      return ApiResponse(
          success: false,
          message: json['message'] ?? 'Failed to remove friend');
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Convert network errors into short user-facing messages.
  String _err(Object e) {
    final msg = e.toString();
    if (msg.contains('TimeoutException')) return 'Request timed out.';
    return 'Network error. Please try again.';
  }
}
