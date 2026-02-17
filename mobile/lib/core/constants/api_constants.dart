class ApiConstants {
  static const String baseUrl = 'http://172.20.10.3:3000/api';
  
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String getMe = '/auth/me';
  
  static const String searchUsers = '/friends/search';
  static const String sendFriendRequest = '/friends/request';
  static const String getPendingRequests = '/friends/requests';
  static const String respondToRequest = '/friends/respond';
  static const String getFriends = '/friends';
  static String deleteFriend(String friendId) => '/friends/$friendId';
  
  static const String updateLocation = '/location/update';
  static const String getFriendsLocations = '/location/friends';
}
