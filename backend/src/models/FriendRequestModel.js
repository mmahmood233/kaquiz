const db = require('../config/database');

class FriendRequestModel {
  static async create(senderId, receiverId) {
    const result = await db.run(`INSERT INTO friend_requests (sender_id, receiver_id) VALUES (?, ?)`, [senderId, receiverId]);
    return this.findById(result.lastID);
  }

  static async findById(id) {
    return await db.get('SELECT * FROM friend_requests WHERE id = ?', [id]);
  }

  static async findByUsers(senderId, receiverId) {
    return await db.get(`SELECT * FROM friend_requests WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)`, [senderId, receiverId, receiverId, senderId]);
  }

  static async getPendingForUser(userId) {
    return await db.all(`
      SELECT fr.*, 
             s.id as sender_id, s.email as sender_email, 
             s.latitude as sender_latitude, s.longitude as sender_longitude,
             r.id as receiver_id, r.email as receiver_email
      FROM friend_requests fr
      INNER JOIN users s ON fr.sender_id = s.id
      INNER JOIN users r ON fr.receiver_id = r.id
      WHERE fr.receiver_id = ? AND fr.status = 'pending'
    `, [userId]);
  }

  static async updateStatus(requestId, status) {
    await db.run('UPDATE friend_requests SET status = ? WHERE id = ?', [status, requestId]);
    return this.findById(requestId);
  }

  static async findWithUsers(requestId) {
    return await db.get(`
      SELECT fr.*, 
             s.id as sender_id, s.email as sender_email,
             r.id as receiver_id, r.email as receiver_email
      FROM friend_requests fr
      INNER JOIN users s ON fr.sender_id = s.id
      INNER JOIN users r ON fr.receiver_id = r.id
      WHERE fr.id = ?
    `, [requestId]);
  }

  static formatWithUsers(row) {
    if (!row) return null;
    return {
      _id: String(row.id),
      sender: {
        _id: String(row.sender_id),
        email: row.sender_email,
        location: {
          latitude: row.sender_latitude || null,
          longitude: row.sender_longitude || null
        }
      },
      receiver: {
        _id: String(row.receiver_id),
        email: row.receiver_email
      },
      status: row.status,
      createdAt: row.created_at
    };
  }
}

module.exports = FriendRequestModel;
