# Friend Finder Mobile App Setup Guide

## Prerequisites

- Flutter SDK (3.x or higher)
- Android Studio / Xcode
- Google Maps API Key

## Getting Started

### 1. Install Dependencies

```bash
cd mobile
flutter pub get
```

### 2. Configure Google Maps API Key

#### For Android:
1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Open `android/app/src/main/AndroidManifest.xml`
3. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key

#### For iOS:
1. Open `ios/Runner/AppDelegate.swift`
2. Add your Google Maps API key (see Google Maps Flutter documentation)

### 3. Update Backend URL

If your backend is not running on `localhost:3000`, update the base URL:

1. Open `lib/core/constants/api_constants.dart`
2. Change `baseUrl` to your backend server URL

For Android emulator connecting to localhost:
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

For iOS simulator connecting to localhost:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

For physical device:
```dart
static const String baseUrl = 'http://YOUR_COMPUTER_IP:3000/api';
```

### 4. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── constants/      # API and app constants
│   └── utils/          # Utility classes (secure storage)
├── data/
│   ├── models/         # Data models
│   ├── repositories/   # Data repositories
│   └── services/       # Services (location tracking)
└── presentation/
    ├── screens/        # UI screens
    └── viewmodels/     # State management (MVVM)
```

## Features

- ✅ Email authentication
- ✅ Friend search by email
- ✅ Send/accept/deny friend requests
- ✅ Delete friends
- ✅ View friends on map
- ✅ Real-time location tracking (every 5 seconds)
- ✅ Offline-first architecture
- ✅ Secure token storage

## Architecture

This app follows **Clean Architecture** principles with **MVVM** pattern:

- **UI Layer**: Screens display state and forward user actions
- **ViewModel Layer**: Manages state and business logic
- **Repository Layer**: Handles data operations
- **Service Layer**: Background services (location tracking)

## Troubleshooting

### Location not working
- Ensure location permissions are granted
- Check that location services are enabled on device
- Verify backend is receiving location updates

### Cannot connect to backend
- Ensure backend server is running
- Check the API base URL is correct
- For emulator/simulator, use appropriate localhost address

### Google Maps not showing
- Verify API key is correctly configured
- Ensure Maps SDK is enabled in Google Cloud Console
- Check internet connection
