function errorHandler(err, req, res, next) {
  // If headers already sent, delegate to default express error handler
  if (res.headersSent) {
    return next(err);
  }
  
  console.error('Error:', err);
  
  const status = err.status || 500;
  const message = err.message || 'Internal Server Error';
  
  res.status(status).json({
    error: message,
    details: err.details || undefined
  });
}

module.exports = errorHandler;
