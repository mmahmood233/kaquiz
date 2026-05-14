// This file contains all friend-related API calls made from Flutter.
// It asks the backend for searchable users, requests, friends, and deletions.
import 'dart:convert';

// http sends requests to the Express backend.
import 'package:http/http.dart' as http;

// ApiConstants gives us endpoint paths, and SecureStorage gives us the JWT token.
import '../../core/constants/api_constants.dart';
import '../../core/utils/secure_storage.dart';

// Backend JSON is converted into these Dart models before reaching the UI.
import '../models/user_model.dart';
import '../models/friend_request_model.dart';
import '../models/api_response.dart';

// Friend API calls should fail quickly instead of leaving buttons loading forever.
const _timeout = Duration(seconds: 10);

// FriendRepository is the data layer for the Friends, Requests, and Search tabs.
class FriendRepository {
  // Every protected backend route needs JSON headers and the saved JWT token.
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // The invite routes need the logged-in user's ID in the URL.
  Future<String?> _getUserId() => SecureStorage.getUserId();

  // Calls GET /api/friends/search.
  // Empty search text asks the backend for every user this account can still add.
  Future<ApiResponse<List<UserModel>>> searchUsers(String email) async {
    try {
      // If text exists, send it as ?email= so the backend filters by email.
      final headers = await _getHeaders();
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.searchUsers}',
      );
      final searchText = email.trim();
      final response = await http
          .get(
            searchText.isEmpty
                ? uri
                : uri.replace(queryParameters: {'email': searchText}),
            headers: headers,
          )
          .timeout(_timeout);

      // The backend returns data.users; convert each item into a UserModel.
      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> usersJson = json['data']['users'];
        return ApiResponse(
          success: true,
          data: usersJson.map((j) => UserModel.fromJson(j)).toList(),
        );
      }
      return ApiResponse(
        success: false,
        message: json['message'] ?? 'Search failed',
      );
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Calls POST /api/invites/{user_id} to send a friend request.
  Future<ApiResponse<void>> sendFriendRequest(String receiverUserId) async {
    try {
      // The receiver ID is placed in the URL so the backend knows who to invite.
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.sendInvite(receiverUserId)}',
            ),
            headers: headers,
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: json['message']);
      }
      return ApiResponse(
        success: false,
        message: json['message'] ?? 'Failed to send invite',
      );
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Calls GET /api/invites/{current_user_id}.
  // The backend returns both requests received by me and requests I sent.
  Future<ApiResponse<List<FriendRequestModel>>> getPendingRequests() async {
    try {
      // Without a saved user ID, the app cannot build the invite URL.
      final userId = await _getUserId();
      if (userId == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

      // Ask the backend for pending invites connected to the logged-in user.
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.getInvites(userId)}',
            ),
            headers: headers,
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final data = json['data'] ?? json;
        final List incoming = data['incoming'] ?? [];
        final List outgoing = data['outgoing'] ?? [];

        // Mark each request so the UI can show it under Received or Sent.
        final requests = [
          ...incoming.map((j) => FriendRequestModel.fromIncoming(j)),
          ...outgoing.map((j) => FriendRequestModel.fromOutgoing(j)),
        ];
        return ApiResponse(success: true, data: requests);
      }
      return ApiResponse(
        success: false,
        message: json['message'] ?? 'Failed to get invites',
      );
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Calls POST /api/invites/{sender_user_id}/accept.
  // The backend changes the invite to accepted and adds both users as friends.
  Future<ApiResponse<void>> acceptInvite(String senderUserId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.acceptInvite(senderUserId)}',
            ),
            headers: headers,
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: json['message']);
      }
      return ApiResponse(
        success: false,
        message: json['message'] ?? 'Failed to accept invite',
      );
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Calls POST /api/invites/{sender_user_id}/decline.
  // The backend marks the invite as denied, so no friendship is created.
  Future<ApiResponse<void>> declineInvite(String senderUserId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.declineInvite(senderUserId)}',
            ),
            headers: headers,
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: json['message']);
      }
      return ApiResponse(
        success: false,
        message: json['message'] ?? 'Failed to decline invite',
      );
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // The ViewModel sends "accept" or "decline"; this routes it to the right API.
  Future<ApiResponse<void>> respondToRequest(
    String senderUserId,
    String action,
  ) async {
    if (action == 'accept') return acceptInvite(senderUserId);
    return declineInvite(senderUserId);
  }

  // Calls GET /api/friends to load the logged-in user's current friend list.
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
        // Support old plain-array responses and the current data.friends shape.
        final List<dynamic> friendsJson = json is List
            ? json
            : (json['data']?['friends'] ?? []);
        return ApiResponse(
          success: true,
          data: friendsJson.map((j) => UserModel.fromJson(j)).toList(),
        );
      }
      final msg = json is Map ? json['message'] : 'Failed to get friends';
      return ApiResponse(
        success: false,
        message: msg ?? 'Failed to get friends',
      );
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Calls DELETE /api/friends/{friend_id}.
  // The backend removes the friendship for both users.
  Future<ApiResponse<void>> deleteFriend(String friendId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.deleteFriend(friendId)}',
            ),
            headers: headers,
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: json['message']);
      }
      return ApiResponse(
        success: false,
        message: json['message'] ?? 'Failed to remove friend',
      );
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Convert network exceptions into short messages for snackbars/forms.
  String _err(Object e) {
    final msg = e.toString();
    if (msg.contains('TimeoutException')) return 'Request timed out.';
    return 'Network error. Please try again.';
  }
}
