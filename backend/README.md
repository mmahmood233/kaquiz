# Friend Finder Backend

Express API for the Friend Finder mobile app.

## What It Does

- Registers and logs in users with email/password
- Issues JWT auth tokens
- Searches users by email
- Sends, accepts, declines, and clears friend requests
- Removes friends
- Stores and returns last known user locations

## Tech Stack

- Node.js
- Express
- SQLite
- JWT
- bcryptjs
- Swagger spec in `swagger.yml`

## Setup

```bash
npm install
cp .env.example .env
npm start
```

The API runs on:

```text
http://localhost:3000
```

Health check:

```bash
curl http://localhost:3000
```

## Environment

`backend/.env` should include:

```env
PORT=3000
JWT_SECRET=change-this-secret
JWT_EXPIRE=7d
NODE_ENV=development
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

The project currently uses SQLite. The database file is created automatically at:

```text
backend/database.sqlite
```

## Commands

```bash
npm start     # Run the API
npm run dev   # Run with nodemon
npm test      # Syntax-check backend source files
```

If port `3000` is already running:

```bash
lsof -ti tcp:3000 | xargs kill -9
npm start
```

## API Routes

```text
GET    /                         Health check
POST   /api/auth/register        Create account
POST   /api/auth/login           Sign in
GET    /api/auth/me              Current user
PUT    /api/users                Update profile
GET    /api/friends              List friends
GET    /api/friends/search       Search addable users
POST   /api/friends/request      Send request by email
GET    /api/friends/requests     Incoming friend requests
POST   /api/friends/respond      Accept or deny a request
DELETE /api/friends/:id          Remove friend
GET    /api/invites/:user_id     Pending invites
POST   /api/invites/:user_id     Send invite
POST   /api/invites/:user_id/accept
POST   /api/invites/:user_id/decline
POST   /api/locations            Save current location
POST   /api/locations/update     Save current location
GET    /api/locations/friends    Friends' last known locations
GET    /api/location/friends     Same as /api/locations/friends
```

## Project Structure

```text
backend/
├── src/
│   ├── config/       # SQLite setup
│   ├── controllers/  # Request handlers
│   ├── middleware/   # Auth and error middleware
│   ├── models/       # SQLite model helpers
│   ├── routes/       # Express routes
│   ├── utils/        # JWT helpers
│   └── server.js     # Entry point
├── swagger.yml
├── package.json
└── .env
```
