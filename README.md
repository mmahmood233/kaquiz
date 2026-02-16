# Friend Finder - Location Tracking App

A fullstack mobile application that allows users to connect with friends and track their last known locations.

## Features

- Email authentication
- Friend search by email
- Send/accept/deny friend requests
- Delete friends from list
- View friends' last known locations on map
- Real-time location updates (every 5 seconds)

## Tech Stack

### Frontend
- Flutter (Dart)
- Google Maps integration
- Clean Architecture (MVVM pattern)

### Backend
- Node.js + Express
- MongoDB
- JWT Authentication
- RESTful API

## Project Structure

```
kaquiz/
├── backend/          # Node.js Express server
└── mobile/           # Flutter mobile app
```

## Getting Started

### Backend Setup
```bash
cd backend
npm install
npm run dev
```

### Mobile Setup
```bash
cd mobile
flutter pub get
flutter run
```

## Architecture Principles

This project follows clean mobile code principles:
- Unidirectional data flow
- Separation of concerns (UI, Domain, Data layers)
- Offline-first thinking
- Predictable state management
- Secure authentication and data storage
