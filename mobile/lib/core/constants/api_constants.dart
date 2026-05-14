// Flutter foundation lets us detect which platform is running the app.
import 'package:flutter/foundation.dart';

// ApiConstants keeps every backend URL/path in one file.
// Repositories use these values when they call the Node/Express API.
class ApiConstants {
  // Base backend URL used before every endpoint below.
  // Android emulator uses 10.0.2.2 to reach the computer's localhost.
  // iPhone physical devices use the Mac's Wi-Fi/hotspot IP, not localhost.
  // Mac, web, and desktop builds use localhost.
  // You can override all defaults with --dart-define=API_BASE_URL=...
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
      return 'http://10.1.204.148:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  // Auth endpoints used for register, login, and "is my token still valid?".
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String getMe = '/auth/me';

  // User profile endpoint used when saving the display name.
  static const String updateUser = '/users';

  // Location endpoints used to save my GPS point and load friends on the map.
  static const String updateLocation = '/locations';
  static const String getFriendsLocations = '/location/friends';

  // Friend endpoints used to list friends, search users, and delete a friend.
  static const String getFriends = '/friends';
  static const String searchUsers = '/friends/search';
  static String deleteFriend(String id) => '/friends/$id';

  // Invite endpoints used for sending, accepting, and declining requests.
  static String getInvites(String userId) => '/invites/$userId';
  static String sendInvite(String userId) => '/invites/$userId';
  static String acceptInvite(String userId) => '/invites/$userId/accept';
  static String declineInvite(String userId) => '/invites/$userId/decline';
}
