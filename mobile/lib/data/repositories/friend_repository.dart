import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/secure_storage.dart';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';
import '../models/api_response.dart';

const _timeout = Duration(seconds: 10);

class FriendRepository {
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<String?> _getUserId() => SecureStorage.getUserId();

  // GET /api/friends/search?email=...
  Future<ApiResponse<List<UserModel>>> searchUsers(String email) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.searchUsers}?email=${Uri.encodeComponent(email)}'),
            headers: headers,
          )
          .timeout(_timeout);

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

  // POST /api/invites/:user_id — send invite by user ID
  Future<ApiResponse<void>> sendFriendRequest(String receiverUserId) async {
    try {
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

  // GET /api/invites/:user_id — returns incoming + outgoing
  Future<ApiResponse<List<FriendRequestModel>>> getPendingRequests() async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        return ApiResponse(success: false, message: 'Not authenticated');
      }

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

  // POST /api/invites/:user_id/accept
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

  // POST /api/invites/:user_id/decline
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

  // respondToRequest — unified wrapper used by ViewModel
  Future<ApiResponse<void>> respondToRequest(
      String senderUserId, String action) async {
    if (action == 'accept') return acceptInvite(senderUserId);
    return declineInvite(senderUserId);
  }

  // GET /api/friends
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
        // Swagger returns a plain array
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

  // DELETE /api/friends/:id
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

  String _err(Object e) {
    final msg = e.toString();
    if (msg.contains('TimeoutException')) return 'Request timed out.';
    return 'Network error. Please try again.';
  }
}
