const db = require('../config/database');
const bcrypt = require('bcryptjs');

class UserModel {
  static async create(email, password) {
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const result = await db.run('INSERT INTO users (email, password) VALUES (?, ?)', [email, hashedPassword]);
    return this.findById(result.lastID);
  }

  static async findByEmail(email) {
    return await db.get('SELECT * FROM users WHERE email = ?', [email]);
  }

  static async findById(id) {
    return await db.get('SELECT * FROM users WHERE id = ?', [id]);
  }

  static async matchPassword(user, enteredPassword) {
    return await bcrypt.compare(enteredPassword, user.password);
  }

  static async updateLocation(userId, latitude, longitude) {
    await db.run(`UPDATE users SET latitude = ?, longitude = ?, location_updated_at = datetime('now') WHERE id = ?`, [latitude, longitude, userId]);
    return this.findById(userId);
  }

  static async getFriends(userId) {
    return await db.all(`SELECT u.* FROM users u INNER JOIN friends f ON u.id = f.friend_id WHERE f.user_id = ?`, [userId]);
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
    const result = await db.get('SELECT 1 FROM friends WHERE user_id = ? AND friend_id = ?', [userId, friendId]);
    return result !== undefined;
  }

  static async searchByEmail(emailPattern, excludeUserId) {
    return await db.all(`SELECT id, email, latitude, longitude, location_updated_at, created_at FROM users WHERE email LIKE ? AND id != ?`, [`%${emailPattern}%`, excludeUserId]);
  }

  static toSafeObject(user) {
    if (!user) return null;
    const { password, ...safeUser } = user;
    return {
      _id: String(user.id),
      email: user.email,
      location: {
        latitude: user.latitude,
        longitude: user.longitude,
        lastUpdated: user.location_updated_at
      },
      createdAt: user.created_at
    };
  }
}

module.exports = UserModel;
