const db = require('../config/database');
const bcrypt = require('bcryptjs');

class UserModel {
  static async create(email, password) {
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    const result = await db.run(
      'INSERT INTO users (email, password) VALUES (?, ?)',
      [email, hashedPassword]
    );
    return this.findById(result.lastID);
  }

  static async findByEmail(email) {
    return db.get('SELECT * FROM users WHERE email = ?', [email]);
  }

  static async findById(id) {
    return db.get('SELECT * FROM users WHERE id = ?', [id]);
  }

  static async matchPassword(user, enteredPassword) {
    return bcrypt.compare(enteredPassword, user.password);
  }

  static async updateProfile(userId, { name, avatar }) {
    const fields = [];
    const values = [];
    if (name !== undefined) { fields.push('name = ?'); values.push(name); }
    if (avatar !== undefined) { fields.push('avatar = ?'); values.push(avatar); }
    if (fields.length === 0) return this.findById(userId);
    values.push(userId);
    await db.run(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`, values);
    return this.findById(userId);
  }

  static async updateLocation(userId, latitude, longitude) {
    await db.run(
      `UPDATE users SET latitude = ?, longitude = ?, location_updated_at = datetime('now') WHERE id = ?`,
      [latitude, longitude, userId]
    );
    return this.findById(userId);
  }

  static async getFriends(userId) {
    return db.all(
      'SELECT u.* FROM users u INNER JOIN friends f ON u.id = f.friend_id WHERE f.user_id = ?',
      [userId]
    );
  }

  static async addFriend(userId, friendId) {
    await db.run('INSERT OR IGNORE INTO friends (user_id, friend_id) VALUES (?, ?)', [userId, friendId]);
    await db.run('INSERT OR IGNORE INTO friends (user_id, friend_id) VALUES (?, ?)', [friendId, userId]);
  }

  static async removeFriend(userId, friendId) {
    await db.run('DELETE FROM friends WHERE user_id = ? AND friend_id = ?', [userId, friendId]);
    await db.run('DELETE FROM friends WHERE user_id = ? AND friend_id = ?', [friendId, userId]);
  }

  static async isFriend(userId, friendId) {
    const result = await db.get(
      'SELECT 1 FROM friends WHERE user_id = ? AND friend_id = ?',
      [userId, friendId]
    );
    return result !== undefined;
  }

  static async searchByEmail(emailPattern, excludeUserId) {
    return db.all(
      'SELECT id, email, name, avatar, latitude, longitude, location_updated_at, created_at FROM users WHERE email LIKE ? AND id != ?',
      [`%${emailPattern}%`, excludeUserId]
    );
  }

  static toPublic(user) {
    if (!user) return null;
    return {
      id: user.id,
      name: user.name || user.email.split('@')[0],
      avatar: user.avatar || null,
      email: user.email
    };
  }

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

module.exports = UserModel;
