// This file contains every login/register API call the Flutter app makes.
// It talks to the Express backend and saves the returned JWT token locally.
import 'dart:convert';

// debugPrint prints request URLs and failures in the Flutter/Xcode console.
import 'package:flutter/foundation.dart';

// http is used to send POST/GET/PUT requests to the backend.
import 'package:http/http.dart' as http;

// ApiConstants contains the backend base URL and endpoint paths.
import '../../core/constants/api_constants.dart';

// SecureStorage stores the JWT token, user ID, and email on the device.
import '../../core/utils/secure_storage.dart';

// These models turn backend JSON into Dart objects the UI can use.
import '../models/user_model.dart';
import '../models/api_response.dart';

// If the backend does not answer in 10 seconds, show a clear network error.
const _timeout = Duration(seconds: 10);

// AuthRepository is the only class that talks to auth backend routes.
class AuthRepository {
  // Calls POST /api/auth/register with email and password.
  // If the backend creates the account, we save the JWT token for later calls.
  Future<ApiResponse<Map<String, dynamic>>> register(
    String email,
    String password,
  ) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}');
      debugPrint('POST $uri');

      // The backend validates the email/password and creates the user in SQLite.
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);
      debugPrint('POST $uri -> ${response.statusCode}');

      // Backend responses are JSON, so decode them before reading message/data.
      final jsonResponse = jsonDecode(response.body);

      // HTTP 201 means the backend successfully created a new account.
      if (response.statusCode == 201) {
        final token = jsonResponse['data']['token'];
        final user = UserModel.fromJson(jsonResponse['data']['user']);

        // Save session data so the user stays logged in after closing the app.
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
      return ApiResponse(success: false, message: _friendlyError(e));
    }
  }

  // Calls POST /api/auth/login.
  // If the backend accepts the credentials, it returns a JWT token and user.
  Future<ApiResponse<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}');
      debugPrint('POST $uri');

      // Send the typed email/password to the backend login endpoint.
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);
      debugPrint('POST $uri -> ${response.statusCode}');

      final jsonResponse = jsonDecode(response.body);

      // HTTP 200 means the backend found the user and the password matched.
      if (response.statusCode == 200) {
        final token = jsonResponse['data']['token'];
        final user = UserModel.fromJson(jsonResponse['data']['user']);

        // Save session data locally so future protected API calls can work.
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
      return ApiResponse(success: false, message: _friendlyError(e));
    }
  }

  // Calls PUT /api/users to update the logged-in user's display name.
  // This request needs the JWT token because the backend must know who is editing.
  Future<ApiResponse<Map<String, dynamic>>> updateProfile(String name) async {
    try {
      // Read the token saved during login/register and send it as Bearer auth.
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

  // Calls GET /api/auth/me.
  // The backend checks the saved token and returns the user linked to it.
  Future<ApiResponse<UserModel>> getMe() async {
    try {
      // If this token is expired or invalid, the backend will reject the request.
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

      // HTTP 200 means the token is still valid and the user can stay signed in.
      if (response.statusCode == 200) {
        final userJson = jsonResponse['data']['user'];
        return ApiResponse(success: true, data: UserModel.fromJson(userJson));
      }
      return ApiResponse(
        success: false,
        message: jsonResponse['message'] ?? 'Session expired',
      );
    } catch (e) {
      return ApiResponse(success: false, message: _friendlyError(e));
    }
  }

  // Logout is local for this app: delete the saved token and user values.
  Future<void> logout() async {
    await SecureStorage.clearAll();
  }

  // Quick local check used before asking the backend if the token is valid.
  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  // Convert Dart/HTTP errors into simple messages that can be shown in the UI.
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
