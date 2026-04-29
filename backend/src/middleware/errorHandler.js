const errorHandler = (err, req, res, next) => {
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Internal Server Error';

  if (err.code === 'SQLITE_CONSTRAINT') {
    statusCode = 400;
    message = 'A conflict occurred with existing data';
  }

  if (process.env.NODE_ENV !== 'production') {
    console.error('[Error]', err.message);
  }

  res.status(statusCode).json({
    success: false,
    message
  });
};

module.exports = errorHandler;
