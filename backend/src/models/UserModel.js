// UserModel is the backend data layer for users, friends, and locations.
// Controllers call these methods instead of writing SQL directly everywhere.
const db = require('../config/database');

// bcrypt hashes passwords before saving and checks passwords during login.
const bcrypt = require('bcryptjs');

// UserModel groups SQLite helper methods for the users/friends tables.
class UserModel {
  // Create a new user row.
  // The raw password is never saved; only the bcrypt hash is stored.
  static async create(email, password) {
    // Generate a salt and hash the password before saving it.
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Insert the account into SQLite.
    const result = await db.run(
      'INSERT INTO users (email, password) VALUES (?, ?)',
      [email, hashedPassword]
    );

    // Return the created user row so the controller can return safe user data.
    return this.findById(result.lastID);
  }

  // Find one user by email. Used by register/login and request-by-email routes.
  static async findByEmail(email) {
    return db.get('SELECT * FROM users WHERE email = ?', [email]);
  }

  // Find one user by ID. Used after verifying JWT tokens and invite IDs.
  static async findById(id) {
    return db.get('SELECT * FROM users WHERE id = ?', [id]);
  }

  // Compare a typed password with the stored bcrypt hash.
  static async matchPassword(user, enteredPassword) {
    return bcrypt.compare(enteredPassword, user.password);
  }

  // Update profile fields that were provided by the profile screen.
  static async updateProfile(userId, { name, avatar }) {
    // Build SQL dynamically so only sent fields are changed.
    const fields = [];
    const values = [];
    if (name !== undefined) { fields.push('name = ?'); values.push(name); }
    if (avatar !== undefined) { fields.push('avatar = ?'); values.push(avatar); }

    // If nothing was sent, just return the current user.
    if (fields.length === 0) return this.findById(userId);

    // Add userId for the WHERE clause and run the update.
    values.push(userId);
    await db.run(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`, values);

    // Return the updated user row.
    return this.findById(userId);
  }

  // Save the user's latest latitude/longitude from Flutter's 5-second updates.
  static async updateLocation(userId, latitude, longitude) {
    await db.run(
      `UPDATE users SET latitude = ?, longitude = ?, location_updated_at = datetime('now') WHERE id = ?`,
      [latitude, longitude, userId]
    );

    // Return the updated user row.
    return this.findById(userId);
  }

  // Get all accepted friends for one user.
  // Friend rows point from the current user to each friend.
  static async getFriends(userId) {
    return db.all(
      'SELECT u.* FROM users u INNER JOIN friends f ON u.id = f.friend_id WHERE f.user_id = ?',
      [userId]
    );
  }

  // Add a friendship in both directions so either user can query their friends.
  static async addFriend(userId, friendId) {
    await db.run('INSERT OR IGNORE INTO friends (user_id, friend_id) VALUES (?, ?)', [userId, friendId]);
    await db.run('INSERT OR IGNORE INTO friends (user_id, friend_id) VALUES (?, ?)', [friendId, userId]);
  }

  // Remove a friendship in both directions.
  static async removeFriend(userId, friendId) {
    await db.run('DELETE FROM friends WHERE user_id = ? AND friend_id = ?', [userId, friendId]);
    await db.run('DELETE FROM friends WHERE user_id = ? AND friend_id = ?', [friendId, userId]);
  }

  // Check if two users are currently friends.
  static async isFriend(userId, friendId) {
    const result = await db.get(
      'SELECT 1 FROM friends WHERE user_id = ? AND friend_id = ?',
      [userId, friendId]
    );
    return result !== undefined;
  }

  // Search addable users by partial email.
  // Excludes the current user, current friends, and users with pending invites.
  static async searchByEmail(emailPattern = '', excludeUserId) {
    const pattern = `%${emailPattern}%`;
    return db.all(
      `SELECT id, email, name, avatar, latitude, longitude, location_updated_at, created_at
       FROM users u
       WHERE u.id != ?
         AND u.email LIKE ?
         AND NOT EXISTS (
           SELECT 1 FROM friends f
           WHERE f.user_id = ? AND f.friend_id = u.id
         )
         AND NOT EXISTS (
           SELECT 1 FROM invites i
           WHERE i.status = 'pending'
             AND (
               (i.sender_id = ? AND i.receiver_id = u.id)
               OR (i.sender_id = u.id AND i.receiver_id = ?)
             )
         )
       ORDER BY u.email COLLATE NOCASE ASC`,
      [excludeUserId, pattern, excludeUserId, excludeUserId, excludeUserId]
    );
  }

  // Return a small public user object for invite/search results.
  static toPublic(user) {
    if (!user) return null;
    return {
      id: user.id,
      name: user.name || user.email.split('@')[0],
      avatar: user.avatar || null,
      email: user.email
    };
  }

  // Return safe user data for API responses.
  // This includes location for map screens but never includes the password hash.
  static toSafeObject(user) {
    if (!user) return null;
    return {
      _id: String(user.id),
      id: user.id,
      email: user.email,
      name: user.name || user.email.split('@')[0],
      avatar: user.avatar || null,
      location: {
        latitude: user.latitude,
        longitude: user.longitude,
        lastUpdated: user.location_updated_at,
        timestamp: user.location_updated_at
      },
      createdAt: user.created_at
    };
  }
}

// Export the model so controllers can use these database helpers.
module.exports = UserModel;
