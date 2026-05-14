// Central error handler for Express.
// If a controller calls next(error), this sends the final JSON response.
const errorHandler = (err, req, res, next) => {
  // Use a custom error status if one exists, otherwise use server error 500.
  let statusCode = err.statusCode || 500;

  // Use the specific error message when available.
  let message = err.message || 'Internal Server Error';

  // SQLite constraint errors often mean duplicate email/request/friendship data.
  if (err.code === 'SQLITE_CONSTRAINT') {
    statusCode = 400;
    message = 'A conflict occurred with existing data';
  }

  // Log backend errors locally while developing.
  if (process.env.NODE_ENV !== 'production') {
    console.error('[Error]', err.message);
  }

  // Send the same error shape the Flutter app expects.
  res.status(statusCode).json({
    success: false,
    message
  });
};

// server.js mounts this after all route files.
module.exports = errorHandler;
