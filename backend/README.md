# Friend Finder Backend API

RESTful API for the Friend Finder location tracking application.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Configure environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. Make sure MongoDB is running locally or update MONGODB_URI in .env

4. Start the server:
```bash
npm run dev
```

The server will run on http://localhost:3000

## API Documentation

See swagger.yml for complete API documentation.

## Project Structure

```
backend/
├── src/
│   ├── config/         # Configuration files
│   ├── models/         # Database models
│   ├── controllers/    # Request handlers
│   ├── routes/         # API routes
│   ├── middleware/     # Custom middleware
│   ├── utils/          # Helper functions
│   └── server.js       # Entry point
├── package.json
└── .env
```
