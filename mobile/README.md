# Friend Finder Mobile

Flutter app for Friend Finder. Users can sign in, add friends, manage friend requests, and view friends' last known locations on Google Maps.

## Features

- Email/password authentication
- User search by email
- Friend request send/accept/decline flow
- Friend removal
- Google Map with custom avatar markers
- Location updates sent to the backend every 5 seconds while the app is open
- Secure token storage

## Setup

```bash
flutter pub get
flutter run
```

For iOS:

```bash
cd ios
pod install
cd ..
flutter run
```

Open the iOS app with:

```text
ios/Runner.xcworkspace
```

not `Runner.xcodeproj`.

## Backend URL

The API base URL is configured in:

```text
lib/core/constants/api_constants.dart
```

You can override it at run time:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_MAC_IP:3000/api
```

Common values:

```text
iOS simulator:      http://localhost:3000/api
Android emulator:  http://10.0.2.2:3000/api
Physical phone:    http://YOUR_MAC_IP:3000/api
```

For a real phone, the phone and Mac must be on the same Wi-Fi/hotspot. Find the Mac IP with:

```bash
ipconfig getifaddr en0
```

## Google Maps

The Google Maps API key must be configured for each platform:

- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/AppDelegate.swift`

Make sure the Maps SDKs are enabled in Google Cloud Console.

## Location Permission

The map and 5-second location updates require location permission.

On iPhone:

```text
Settings > Privacy & Security > Location Services > Friend Finder
```

Choose **While Using the App** and turn on **Precise Location**.

If iOS previously denied permission and the prompt does not appear again, delete the app from the phone and run it again.

## Commands

```bash
flutter analyze
flutter test
flutter clean
flutter pub get
flutter run
```

Do not use `--no-codesign` when installing on a real iPhone.

## Project Structure

```text
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
└── presentation/
    ├── screens/
    ├── viewmodels/
    └── widgets/
```
