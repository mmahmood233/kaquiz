// Central error handler for Express.
// If a controller calls next(error), the request ends here.
const errorHandler = (err, req, res, next) => {
  // Use the error status if it exists, otherwise use 500.
  let statusCode = err.statusCode || 500;

  // Use the error message if it exists, otherwise use a general message.
  let message = err.message || 'Internal Server Error';

  // SQLite constraint errors usually mean duplicate or invalid related data.
  if (err.code === 'SQLITE_CONSTRAINT') {
    statusCode = 400;
    message = 'A conflict occurred with existing data';
  }

  // Log errors locally, but avoid noisy production logs.
  if (process.env.NODE_ENV !== 'production') {
    console.error('[Error]', err.message);
  }

  // Send a consistent JSON error response.
  res.status(statusCode).json({
    success: false,
    message
  });
};

// Export this so server.js can use it after all routes.
module.exports = errorHandler;
