// This file contains the map/location API calls made by the Flutter app.
// It sends my location to the backend and loads my friends' saved locations.
import 'dart:convert';

// http sends requests to the Express backend.
import 'package:http/http.dart' as http;

// ApiConstants has endpoint paths, and SecureStorage gives us the JWT token.
import '../../core/constants/api_constants.dart';
import '../../core/utils/secure_storage.dart';

// Backend friend/location JSON is converted into these models.
import '../models/user_model.dart';
import '../models/api_response.dart';

// Location calls run often, so keep the timeout short to avoid blocking the map.
const _timeout = Duration(seconds: 8);

// LocationRepository is the only class that talks to location backend routes.
class LocationRepository {
  // Location routes are protected, so each request sends the saved JWT token.
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Calls POST /api/locations.
  // The backend saves these coordinates as the user's latest known location.
  Future<ApiResponse<void>> updateLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      // Send only latitude and longitude; the backend knows the user from the JWT.
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateLocation}'),
            headers: headers,
            body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
          )
          .timeout(_timeout);

      // Decode the backend response so validation errors can be shown if needed.
      final dynamic json = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : <String, dynamic>{};

      // HTTP 200 means SQLite was updated with the latest coordinates.
      if (response.statusCode == 200) {
        return ApiResponse(success: true);
      }
      return ApiResponse(
        success: false,
        message: json is Map
            ? json['message'] ?? 'Location update failed'
            : 'Location update failed',
      );
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Calls GET /api/location/friends.
  // The backend returns friends plus their last saved locations.
  Future<ApiResponse<List<UserModel>>> getFriendsLocations() async {
    try {
      // Ask the backend for friends that the current user is allowed to see.
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.getFriendsLocations}',
            ),
            headers: headers,
          )
          .timeout(_timeout);

      final dynamic json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // The current backend returns friends inside data.friends.
        final List<dynamic> friendsJson = json is List
            ? json
            : (json['data']?['friends'] ?? []);

        // The map should only show friends that have real coordinates.
        final withLocation = friendsJson
            .map((j) => UserModel.fromJson(j))
            .where(
              (u) =>
                  u.location != null &&
                  (u.location!.latitude != 0.0 || u.location!.longitude != 0.0),
            )
            .toList();
        return ApiResponse(success: true, data: withLocation);
      }
      return ApiResponse(success: false, message: 'Failed to get locations');
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Convert backend/network failures into simple text for the map screen.
  String _err(Object e) {
    final msg = e.toString();
    if (msg.contains('TimeoutException') || msg.contains('timed out')) {
      return 'Request timed out.';
    }
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Server is unavailable.';
    }
    return 'Network error. Please try again.';
  }
}
