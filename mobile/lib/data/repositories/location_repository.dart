import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/secure_storage.dart';
import '../models/user_model.dart';
import '../models/api_response.dart';

class LocationRepository {
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<ApiResponse<void>> updateLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateLocation}'),
        headers: headers,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
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
          message: jsonResponse['message'] ?? 'Failed to update location',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<List<UserModel>>> getFriendsLocations() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getFriendsLocations}'),
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
          message: jsonResponse['message'] ?? 'Failed to get locations',
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
