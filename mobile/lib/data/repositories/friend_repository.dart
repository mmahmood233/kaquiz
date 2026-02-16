import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/secure_storage.dart';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';
import '../models/api_response.dart';

class FriendRepository {
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<ApiResponse<List<UserModel>>> searchUsers(String email) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.searchUsers}?email=$email'),
        headers: headers,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonResponse['data']['users'];
        final users = usersJson.map((json) => UserModel.fromJson(json)).toList();

        return ApiResponse(
          success: true,
          data: users,
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Search failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<void>> sendFriendRequest(String receiverEmail) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.sendFriendRequest}'),
        headers: headers,
        body: jsonEncode({'receiverEmail': receiverEmail}),
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: jsonResponse['message'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to send request',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<List<FriendRequestModel>>> getPendingRequests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getPendingRequests}'),
        headers: headers,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> requestsJson = jsonResponse['data']['requests'];
        final requests = requestsJson
            .map((json) => FriendRequestModel.fromJson(json))
            .toList();

        return ApiResponse(
          success: true,
          data: requests,
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to get requests',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<void>> respondToRequest(
    String requestId,
    String action,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.respondToRequest}'),
        headers: headers,
        body: jsonEncode({
          'requestId': requestId,
          'action': action,
        }),
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: jsonResponse['message'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to respond',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<List<UserModel>>> getFriends() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getFriends}'),
        headers: headers,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> friendsJson = jsonResponse['data']['friends'];
        final friends = friendsJson.map((json) => UserModel.fromJson(json)).toList();

        return ApiResponse(
          success: true,
          data: friends,
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to get friends',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<void>> deleteFriend(String friendId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteFriend(friendId)}'),
        headers: headers,
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: jsonResponse['message'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to delete friend',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}
