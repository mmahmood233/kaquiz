import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/secure_storage.dart';
import '../models/user_model.dart';
import '../models/api_response.dart';

const _timeout = Duration(seconds: 8);

class LocationRepository {
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // POST /api/locations  (swagger: POST /locations)
  Future<ApiResponse<void>> updateLocation(
      double latitude, double longitude) async {
    try {
      final headers = await _getHeaders();
      await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateLocation}'),
            headers: headers,
            body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
          )
          .timeout(_timeout);
      return ApiResponse(success: true);
    } catch (_) {
      return ApiResponse(success: false, message: 'Location update failed');
    }
  }

  // GET /api/friends — swagger GET /friends returns locations embedded
  Future<ApiResponse<List<UserModel>>> getFriendsLocations() async {
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
        final List<dynamic> friendsJson =
            json is List ? json : (json['data']?['friends'] ?? []);
        final withLocation = friendsJson
            .map((j) => UserModel.fromJson(j))
            .where((u) =>
                u.location != null &&
                (u.location!.latitude != 0.0 || u.location!.longitude != 0.0))
            .toList();
        return ApiResponse(success: true, data: withLocation);
      }
      return ApiResponse(success: false, message: 'Failed to get locations');
    } catch (_) {
      return ApiResponse(success: false, message: 'Network error');
    }
  }
}
