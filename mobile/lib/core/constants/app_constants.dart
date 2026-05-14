// AppConstants stores small app-wide values reused by multiple Flutter files.
class AppConstants {
  // Name shown in app titles and labels.
  static const String appName = 'Friend Finder';

  // The requirement says to send location every 5 seconds while the app is open.
  static const int locationUpdateInterval = 5;

  // Zoom level used when the map centers on the current user or a friend.
  static const double defaultZoom = 14.0;
}
