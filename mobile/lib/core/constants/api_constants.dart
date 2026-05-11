// Flutter foundation lets us detect web, Android, iOS, and other platforms.
import 'package:flutter/foundation.dart';

// ApiConstants keeps all backend URLs in one place.
class ApiConstants {
  // Base backend URL.
  // Android emulator uses 10.0.2.2 to reach the computer's localhost.
  // iPhone physical devices use the Mac's Wi-Fi/hotspot IP, not localhost.
  // Mac, web, and desktop builds use localhost.
  // You can override this with --dart-define=API_BASE_URL=...
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS) {
      return 'http://localhost:3000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://192.168.3.55:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  // Authentication endpoints.
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String getMe = '/auth/me';

  // User profile endpoint.
  static const String updateUser = '/users';

  // Location endpoints.
  static const String updateLocation = '/locations';
  static const String getFriendsLocations = '/location/friends';

  // Friend endpoints.
  static const String getFriends = '/friends';
  static const String searchUsers = '/friends/search';
  static String deleteFriend(String id) => '/friends/$id';

  // Invite endpoints used by the Flutter UI.
  static String getInvites(String userId) => '/invites/$userId';
  static String sendInvite(String userId) => '/invites/$userId';
  static String acceptInvite(String userId) => '/invites/$userId/accept';
  static String declineInvite(String userId) => '/invites/$userId/decline';
}
