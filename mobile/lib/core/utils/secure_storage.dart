// flutter_secure_storage saves sensitive values in encrypted phone storage.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// SecureStorage stores the login session returned by the backend.
// The app reads these values later to call protected API routes.
class SecureStorage {
  // One shared secure storage instance used by all repository classes.
  static const _storage = FlutterSecureStorage();

  // Storage keys used to read/write session values safely.
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';

  // Save the JWT token returned by /api/auth/login or /api/auth/register.
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Read the JWT token before calling protected backend routes.
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Save the logged-in user's backend ID for invite routes.
  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  // Read the current user's backend ID.
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // Save the email so the app can reuse/display it if needed.
  static Future<void> saveEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
  }

  // Read the saved email for account/session features.
  static Future<String?> getEmail() async {
    return await _storage.read(key: _emailKey);
  }

  // Remove all saved session data on logout.
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
