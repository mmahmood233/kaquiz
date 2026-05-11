# Friend Finder

Friend Finder is a fullstack mobile app for finding friends by email, sending friend requests, and sharing each user's last known location on a map.

## Features

- Email/password authentication
- Search users by email
- Send, accept, and decline friend requests
- Remove friends from the friends list
- View friends' last known locations on Google Maps
- Send the signed-in user's location to the backend every 5 seconds while the app is open
- Simple Snap Map-inspired Flutter UI with custom avatar map markers

## Tech Stack

### Backend

- Node.js
- Express
- SQLite
- JWT authentication
- Swagger API spec in `backend/swagger.yml`

### Mobile

- Flutter
- Provider/MVVM state management
- Google Maps Flutter
- Geolocator
- Secure token storage

## Project Structure

```text
kaquiz/
├── backend/       # Express API and SQLite database
├── mobile/        # Flutter mobile app
├── README.md      # Main setup guide
└── DEPLOYMENT.md  # Extra deployment notes
```

## Backend Setup

```bash
cd backend
npm install
cp .env.example .env
npm start
```

The backend runs on:

```text
http://localhost:3000
```

Health check:

```bash
curl http://localhost:3000
```

If port `3000` is already in use:

```bash
lsof -ti tcp:3000 | xargs kill -9
npm start
```

Backend checks:

```bash
npm test
```

## Mobile Setup

```bash
cd mobile
flutter pub get
flutter run
```

For iOS after a clean install:

```bash
cd mobile/ios
pod install
cd ..
flutter run
```

Use `mobile/ios/Runner.xcworkspace` when opening the iOS project in Xcode.

## Backend URL For Devices

The Flutter app reads its API URL from `mobile/lib/core/constants/api_constants.dart`.

Defaults:

- macOS/web: `http://localhost:3000/api`
- Android emulator: `http://10.0.2.2:3000/api`
- iOS physical device: the Mac's Wi-Fi IP, for example `http://192.168.3.55:3000/api`

For a physical phone, the phone and Mac must be on the same Wi-Fi/hotspot. If the Mac IP changes, run with:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_MAC_IP:3000/api
```

Find the Mac Wi-Fi IP:

```bash
ipconfig getifaddr en0
```

## Google Maps

Set the Google Maps API key in these places:

- `backend/.env` as `GOOGLE_MAPS_API_KEY`
- Android: `mobile/android/app/src/main/AndroidManifest.xml`
- iOS: `mobile/ios/Runner/AppDelegate.swift`

Do not commit real API keys to public repositories.

## Location Permission

The app can only update location every 5 seconds after the device grants permission.

On iPhone:

```text
Settings > Privacy & Security > Location Services > Friend Finder
```

Set it to **While Using the App** and enable **Precise Location**.

## Useful Commands

```bash
# Backend
cd backend
npm start
npm test

# Mobile
cd mobile
flutter analyze
flutter test
flutter clean
flutter pub get
flutter run
```

## Notes

- The backend stores data in `backend/database.sqlite`.
- WebSockets are not required for this project. The app sends location updates every 5 seconds and polls friend locations from the API.
- Do not use `--no-codesign` when installing on a real iPhone.
