import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/secure_storage.dart';
import '../models/user_model.dart';
import '../models/api_response.dart';

const _timeout = Duration(seconds: 10);

class AuthRepository {
  Future<ApiResponse<Map<String, dynamic>>> register(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final token = jsonResponse['data']['token'];
        final user = UserModel.fromJson(jsonResponse['data']['user']);

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

  Future<ApiResponse<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = jsonResponse['data']['token'];
        final user = UserModel.fromJson(jsonResponse['data']['user']);

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

  Future<ApiResponse<Map<String, dynamic>>> updateProfile(String name) async {
    try {
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

  Future<ApiResponse<UserModel>> getMe() async {
    try {
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

  Future<void> logout() async {
    await SecureStorage.clearAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('TimeoutException') || msg.contains('timed out')) {
      return 'Cannot reach server. Check your connection.';
    }
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Server is unavailable. Try again later.';
    }
    return 'Network error. Please try again.';
  }
}
