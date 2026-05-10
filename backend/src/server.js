// Load variables from backend/.env into process.env.
require('dotenv').config();

// Express creates the HTTP API server.
const express = require('express');

// cors allows the mobile app/web app to call this backend.
const cors = require('cors');

// helmet adds basic security headers.
const helmet = require('helmet');

// morgan logs HTTP requests during development.
const morgan = require('morgan');

// Importing the database file initializes the SQLite tables.
const db = require('./config/database');

// Shared error handler for unexpected backend errors.
const errorHandler = require('./middleware/errorHandler');

// Create the Express app.
const app = express();

// Add security and request parsing middleware.
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Log requests only when running locally/development.
if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev'));
}

// Health check route.
// You can open http://localhost:3000 to confirm the API is running.
app.get('/', (req, res) => {
  res.json({ success: true, message: 'Friend Tracker API is running', version: '1.0.0' });
});

// Main API routes.
// Each route file points URLs to controller functions.
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/locations', require('./routes/locations'));

// Swagger uses /api/location, while the app also supports /api/locations.
app.use('/api/location', require('./routes/locations'));
app.use('/api/invites', require('./routes/invites'));
app.use('/api/friends', require('./routes/friends'));

// This must come after routes so it can catch route errors.
app.use(errorHandler);

// Start the server on the configured port.
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
