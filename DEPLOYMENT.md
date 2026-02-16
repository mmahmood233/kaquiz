# Friend Finder - Deployment Guide

## Backend Deployment

### Prerequisites
- Node.js 16+ installed
- MongoDB instance (local or cloud like MongoDB Atlas)

### Steps

1. **Install dependencies**
```bash
cd backend
npm install
```

2. **Configure environment variables**
```bash
cp .env.example .env
```

Edit `.env` file:
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/friend-finder
# Or use MongoDB Atlas:
# MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/friend-finder
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRE=7d
NODE_ENV=production
```

3. **Start MongoDB** (if running locally)
```bash
# macOS with Homebrew
brew services start mongodb-community

# Linux
sudo systemctl start mongod

# Windows
net start MongoDB
```

4. **Run the server**
```bash
# Development
npm run dev

# Production
npm start
```

The API will be available at `http://localhost:3000`

### API Endpoints

See `backend/swagger.yml` for complete API documentation.

**Base URL**: `http://localhost:3000/api`

**Authentication**:
- POST `/auth/register` - Register new user
- POST `/auth/login` - Login user
- GET `/auth/me` - Get current user (requires auth)

**Friends**:
- GET `/friends/search?email=` - Search users
- POST `/friends/request` - Send friend request
- GET `/friends/requests` - Get pending requests
- POST `/friends/respond` - Accept/deny request
- GET `/friends` - Get friends list
- DELETE `/friends/:friendId` - Remove friend

**Location**:
- POST `/location/update` - Update location
- GET `/location/friends` - Get friends locations

## Mobile App Deployment

### Android

1. **Build APK**
```bash
cd mobile
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

2. **Build App Bundle** (for Play Store)
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS

1. **Build for iOS**
```bash
cd mobile
flutter build ios --release
```

2. **Archive in Xcode**
- Open `ios/Runner.xcworkspace` in Xcode
- Select Product > Archive
- Follow App Store submission process

## Production Considerations

### Backend

1. **Use environment variables** for sensitive data
2. **Enable HTTPS** with SSL/TLS certificates
3. **Set up CORS** properly for your frontend domain
4. **Use MongoDB Atlas** or managed database service
5. **Implement rate limiting** to prevent abuse
6. **Add logging** and monitoring (e.g., Winston, Sentry)
7. **Use PM2** or similar for process management

### Mobile App

1. **Update API base URL** to production server
2. **Add proper error handling** and retry logic
3. **Implement analytics** (Firebase, Mixpanel)
4. **Add crash reporting** (Firebase Crashlytics)
5. **Optimize images** and assets
6. **Test on multiple devices** and OS versions
7. **Configure proper app signing** for release builds

## Testing the Full Stack

1. Start backend server
2. Create two user accounts on mobile app
3. Search for second user by email
4. Send friend request
5. Accept friend request on second device
6. Verify both users appear on map
7. Verify location updates every 5 seconds

## Security Checklist

- [ ] JWT secret is strong and unique
- [ ] Passwords are hashed with bcrypt
- [ ] HTTPS is enabled in production
- [ ] API keys are not hardcoded
- [ ] Input validation is implemented
- [ ] Rate limiting is configured
- [ ] CORS is properly configured
- [ ] Tokens are stored securely on mobile
- [ ] Location data is transmitted securely
