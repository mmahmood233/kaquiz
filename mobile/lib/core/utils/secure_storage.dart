// flutter_secure_storage saves sensitive values in encrypted platform storage.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// SecureStorage is a small helper for saved login/session data.
class SecureStorage {
  // One shared secure storage instance.
  static const _storage = FlutterSecureStorage();
  
  // Storage keys used by this app.
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';

  // Save the JWT token after login/register.
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Read the saved JWT token.
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Save the logged-in user's ID.
  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  // Read the saved user ID.
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // Save the logged-in user's email.
  static Future<void> saveEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
  }

  // Read the saved email.
  static Future<String?> getEmail() async {
    return await _storage.read(key: _emailKey);
  }

  // Remove all saved session data on logout.
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
