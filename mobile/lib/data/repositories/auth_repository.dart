// jsonEncode/jsonDecode convert Dart maps to JSON and back.
import 'dart:convert';

// debugPrint writes useful request logs in Xcode/Flutter console.
import 'package:flutter/foundation.dart';

// http sends requests to the backend API.
import 'package:http/http.dart' as http;

// App API paths.
import '../../core/constants/api_constants.dart';

// Secure local token storage.
import '../../core/utils/secure_storage.dart';

// User and response models.
import '../models/user_model.dart';
import '../models/api_response.dart';

// Stop network calls if the backend does not answer quickly.
const _timeout = Duration(seconds: 10);

// AuthRepository handles all authentication API calls.
class AuthRepository {
  // Create a new account.
  Future<ApiResponse<Map<String, dynamic>>> register(
    String email,
    String password,
  ) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}');
      debugPrint('POST $uri');

      // Send email and password to the register endpoint.
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);
      debugPrint('POST $uri -> ${response.statusCode}');

      // Decode backend JSON response.
      final jsonResponse = jsonDecode(response.body);

      // 201 means the account was created.
      if (response.statusCode == 201) {
        final token = jsonResponse['data']['token'];
        final user = UserModel.fromJson(jsonResponse['data']['user']);

        // Save token/user info so the app stays logged in.
        await SecureStorage.saveToken(token);
        await SecureStorage.saveUserId(user.id);
        await SecureStorage.saveEmail(user.email);

        return ApiResponse(
          success: true,
          message: jsonResponse['message'],
          data: jsonResponse['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: _friendlyError(e),
      );
    }
  }

  // Login with email and password.
  Future<ApiResponse<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}');
      debugPrint('POST $uri');

      // Send credentials to the login endpoint.
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);
      debugPrint('POST $uri -> ${response.statusCode}');

      final jsonResponse = jsonDecode(response.body);

      // 200 means login succeeded.
      if (response.statusCode == 200) {
        final token = jsonResponse['data']['token'];
        final user = UserModel.fromJson(jsonResponse['data']['user']);

        // Save session data locally.
        await SecureStorage.saveToken(token);
        await SecureStorage.saveUserId(user.id);
        await SecureStorage.saveEmail(user.email);

        return ApiResponse(
          success: true,
          message: jsonResponse['message'],
          data: jsonResponse['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: _friendlyError(e),
      );
    }
  }

  // Update the logged-in user's display name.
  Future<ApiResponse<Map<String, dynamic>>> updateProfile(String name) async {
    try {
      // Authenticated requests need the saved JWT token.
      final token = await SecureStorage.getToken();
      final response = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateUser}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'name': name}),
          )
          .timeout(_timeout);

      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: jsonResponse['message'],
          data: jsonResponse['data'],
        );
      }
      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ?? 'Update failed',
      );
    } catch (e) {
      return ApiResponse(success: false, message: _friendlyError(e));
    }
  }

  // Load the current user from the saved token.
  Future<ApiResponse<UserModel>> getMe() async {
    try {
      // Read saved token and ask backend who this token belongs to.
      final token = await SecureStorage.getToken();
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getMe}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      final jsonResponse = jsonDecode(response.body);

      // 200 means the token is valid.
      if (response.statusCode == 200) {
        final userJson = jsonResponse['data']['user'];
        return ApiResponse(
          success: true,
          data: UserModel.fromJson(userJson),
        );
      }
      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ?? 'Session expired',
      );
    } catch (e) {
      return ApiResponse(success: false, message: _friendlyError(e));
    }
  }

  // Log out by clearing saved session data.
  Future<void> logout() async {
    await SecureStorage.clearAll();
  }

  // The app is considered logged in if a token exists.
  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  // Convert technical network errors into user-friendly messages.
  String _friendlyError(Object e) {
    final msg = e.toString();
    final api = ApiConstants.baseUrl;
    debugPrint('Network error for $api: $msg');
    if (msg.contains('TimeoutException') || msg.contains('timed out')) {
      return 'Cannot reach server at $api.';
    }
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Server is unavailable at $api.';
    }
    return 'Network error at $api.';
  }
}
