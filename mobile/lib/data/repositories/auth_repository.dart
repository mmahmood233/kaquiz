import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/secure_storage.dart';
import '../models/user_model.dart';
import '../models/api_response.dart';

class AuthRepository {
  Future<ApiResponse<Map<String, dynamic>>> register(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

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
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

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
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}
