// sqlite3 is the database library used by this backend.
// The app stores users, friends, requests, and last known locations in SQLite.
const sqlite3 = require('sqlite3').verbose();

// path builds a safe file path to backend/database.sqlite.
const path = require('path');

// Store the database file inside the backend folder so it is easy to find.
const dbPath = path.join(__dirname, '../../database.sqlite');

// Open a connection to SQLite.
// If database.sqlite does not exist, SQLite creates it automatically.
const db = new sqlite3.Database(dbPath);

// Run setup queries in order when the server starts.
// This makes local setup simple because tables are created automatically.
db.serialize(() => {
  // users stores accounts, profile fields, and each user's last known location.
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      name TEXT,
      avatar TEXT,
      latitude REAL,
      longitude REAL,
      location_updated_at TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // Add name/avatar columns for older databases that were made before these fields.
  // The empty callback ignores the expected duplicate-column error.
  db.run(`ALTER TABLE users ADD COLUMN name TEXT`, () => {});
  db.run(`ALTER TABLE users ADD COLUMN avatar TEXT`, () => {});

  // friends stores accepted friendships.
  // Each friendship is stored in both directions:
  // user A -> user B and user B -> user A.
  db.run(`
    CREATE TABLE IF NOT EXISTS friends (
      user_id INTEGER NOT NULL,
      friend_id INTEGER NOT NULL,
      PRIMARY KEY (user_id, friend_id),
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (friend_id) REFERENCES users(id)
    )
  `);

  // invites stores friend requests.
  // status is pending, accepted, or denied.
  db.run(`
    CREATE TABLE IF NOT EXISTS invites (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sender_id INTEGER NOT NULL,
      receiver_id INTEGER NOT NULL,
      status TEXT DEFAULT 'pending',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (sender_id) REFERENCES users(id),
      FOREIGN KEY (receiver_id) REFERENCES users(id),
      UNIQUE(sender_id, receiver_id)
    )
  `);

  // If an old friend_requests table exists, copy its data into invites.
  // INSERT OR IGNORE avoids duplicate rows during repeated server starts.
  db.run(`
    INSERT OR IGNORE INTO invites (id, sender_id, receiver_id, status, created_at)
    SELECT id, sender_id, receiver_id, status, created_at FROM friend_requests
  `, () => {});

  console.log('Database initialized');
});

// sqlite3 uses callbacks by default.
// This wrapper lets controllers/models use async/await instead.
const dbAsync = {
  // Run INSERT, UPDATE, and DELETE queries.
  // lastID is useful after inserts; changes tells how many rows were updated/deleted.
  run: (sql, params = []) => new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve({ lastID: this.lastID, changes: this.changes });
    });
  }),

  // Read one row from the database, or undefined when nothing matches.
  get: (sql, params = []) => new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  }),

  // Read many rows from the database and return them as an array.
  all: (sql, params = []) => new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  })
};

// Export the async database helper so controllers and models can share it.
module.exports = dbAsync;
