// JSON helpers for request and response bodies.
import 'dart:convert';

// HTTP client for backend calls.
import 'package:http/http.dart' as http;

// API paths and saved token helper.
import '../../core/constants/api_constants.dart';
import '../../core/utils/secure_storage.dart';

// Models used by this repository.
import '../models/user_model.dart';
import '../models/api_response.dart';

// Location calls should fail quickly so they do not block the UI.
const _timeout = Duration(seconds: 8);

// LocationRepository handles location-related backend calls.
class LocationRepository {
  // Build headers for authenticated JSON requests.
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Send current latitude and longitude to the backend.
  Future<ApiResponse<void>> updateLocation(
      double latitude, double longitude) async {
    try {
      // Send the latest location for the logged-in user.
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateLocation}'),
            headers: headers,
            body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
          )
          .timeout(_timeout);

      // Decode response so backend error messages can be shown.
      final dynamic json = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : <String, dynamic>{};

      // 200 means location was saved.
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

  // Get friends that have a last known location.
  Future<ApiResponse<List<UserModel>>> getFriendsLocations() async {
    try {
      // Ask backend for friends with location data.
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.getFriendsLocations}'),
            headers: headers,
          )
          .timeout(_timeout);

      final dynamic json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // The backend returns friends inside data.friends.
        final List<dynamic> friendsJson =
            json is List ? json : (json['data']?['friends'] ?? []);

        // Only keep friends that actually have usable coordinates.
        final withLocation = friendsJson
            .map((j) => UserModel.fromJson(j))
            .where((u) =>
                u.location != null &&
                (u.location!.latitude != 0.0 || u.location!.longitude != 0.0))
            .toList();
        return ApiResponse(success: true, data: withLocation);
      }
      return ApiResponse(success: false, message: 'Failed to get locations');
    } catch (e) {
      return ApiResponse(success: false, message: _err(e));
    }
  }

  // Convert technical errors into simple UI messages.
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
