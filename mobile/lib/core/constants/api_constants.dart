import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (kIsWeb) return 'http://localhost:3000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String getMe = '/auth/me';

  // Users
  static const String updateUser = '/users';

  // Locations (swagger: POST /locations)
  static const String updateLocation = '/locations';
  static const String getFriendsLocations = '/location/friends';

  // Friends (swagger: GET /friends, DELETE /friends/:id)
  static const String getFriends = '/friends';
  static const String searchUsers = '/friends/search';
  static String deleteFriend(String id) => '/friends/$id';

  // Invites (swagger: /invites/{user_id})
  static String getInvites(String userId) => '/invites/$userId';
  static String sendInvite(String userId) => '/invites/$userId';
  static String acceptInvite(String userId) => '/invites/$userId/accept';
  static String declineInvite(String userId) => '/invites/$userId/decline';
}
