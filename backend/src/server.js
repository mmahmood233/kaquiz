// Load backend/.env values like PORT and JWT_SECRET into process.env.
require('dotenv').config();

// Express is the Node.js framework that handles API routes for the Flutter app.
const express = require('express');

// cors lets the Flutter app call this API from simulators, phones, or web.
const cors = require('cors');

// helmet adds basic HTTP security headers to responses.
const helmet = require('helmet');

// morgan prints each API request in the terminal during development.
const morgan = require('morgan');

// Requiring database.js opens SQLite and creates the needed tables.
const db = require('./config/database');

// Shared error handler returns consistent JSON when controllers throw errors.
const errorHandler = require('./middleware/errorHandler');

// Create the Express app object. All middleware and routes attach to this.
const app = express();

// Add security middleware and allow JSON request bodies from Flutter.
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Log requests only in development so production logs stay cleaner.
if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev'));
}

// Health check route used to confirm the backend server is reachable.
// Example: open http://localhost:3000 or the Mac IP from iPhone Safari.
app.get('/', (req, res) => {
  res.json({ success: true, message: 'Friend Tracker API is running', version: '1.0.0' });
});

// Main API route groups.
// The Flutter app calls these paths through ApiConstants in mobile/lib.
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/locations', require('./routes/locations'));

// Support both /api/location and /api/locations so Swagger and Flutter both work.
app.use('/api/location', require('./routes/locations'));
app.use('/api/invites', require('./routes/invites'));
app.use('/api/friends', require('./routes/friends'));

// This must be after routes. Controllers call next(error) to reach it.
app.use(errorHandler);

// Start listening for requests. Locally this is usually port 3000.
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
