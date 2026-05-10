// sqlite3 is the database library used by this backend.
const sqlite3 = require('sqlite3').verbose();

// path helps us build a safe file path to the SQLite database file.
const path = require('path');

// Store the database file inside the backend folder.
const dbPath = path.join(__dirname, '../../database.sqlite');

// Open a connection to the SQLite database.
// If database.sqlite does not exist yet, SQLite will create it.
const db = new sqlite3.Database(dbPath);

// Run the setup queries one after another.
// This creates the tables the app needs when the server starts.
db.serialize(() => {
  // The users table stores accounts, profile data, and last known location.
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

  // Add name/avatar columns if an older database was created before these fields existed.
  // The empty callback ignores the "duplicate column" error if the column already exists.
  db.run(`ALTER TABLE users ADD COLUMN name TEXT`, () => {});
  db.run(`ALTER TABLE users ADD COLUMN avatar TEXT`, () => {});

  // The friends table stores friendship links.
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

  // The invites table stores friend requests.
  // status can be pending, accepted, or denied.
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

  // Move old friend request data into the newer invites table if that old table exists.
  // INSERT OR IGNORE avoids creating duplicate invite rows.
  db.run(`
    INSERT OR IGNORE INTO invites (id, sender_id, receiver_id, status, created_at)
    SELECT id, sender_id, receiver_id, status, created_at FROM friend_requests
  `, () => {});

  console.log('Database initialized');
});

// sqlite3 uses callbacks by default.
// This wrapper lets the rest of the app use async/await instead.
const dbAsync = {
  // Run INSERT, UPDATE, and DELETE queries.
  // It returns the new row ID and number of changed rows.
  run: (sql, params = []) => new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve({ lastID: this.lastID, changes: this.changes });
    });
  }),

  // Read one row from the database.
  get: (sql, params = []) => new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  }),

  // Read many rows from the database.
  all: (sql, params = []) => new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  })
};

// Export the async database helper so controllers and models can use it.
module.exports = dbAsync;
