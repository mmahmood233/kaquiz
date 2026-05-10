// Flutter app delegate integration.
import Flutter

// UIKit is the base iOS UI framework.
import UIKit

// GoogleMaps is required by google_maps_flutter on iOS.
import GoogleMaps

// Main iOS app delegate.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Provide the Google Maps API key before Flutter plugins start.
    GMSServices.provideAPIKey("AIzaSyBQaI0TqzQQpJvneXmR5pP9AacofKqOayk")

    // Register Flutter plugins like Google Maps and Geolocator.
    GeneratedPluginRegistrant.register(with: self)

    // Continue normal Flutter app startup.
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
