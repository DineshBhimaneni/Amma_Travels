const db = require('../config/db');

const createUsersTable = async () => {
  const query = `
    CREATE TABLE IF NOT EXISTS users (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      email VARCHAR(255) NOT NULL UNIQUE,
      password VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `;
  try {
    await db.query(query);
    // Add fcm_token column if not present in existing table
    const [cols] = await db.query("SHOW COLUMNS FROM users LIKE 'fcm_token'");
    if (cols.length === 0) {
      await db.query("ALTER TABLE users ADD COLUMN fcm_token TEXT");
      console.log('fcm_token column added to users table');
    }
    console.log('Users table ready');
  } catch (error) {
    console.error('Error creating users table:', error);
  }
};

const findUserByEmail = async (email) => {
  const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
  return rows[0];
};

const findUserById = async (id) => {
  const [rows] = await db.query('SELECT id, name, email, fcm_token, created_at FROM users WHERE id = ?', [id]);
  return rows[0];
};

const updateFcmToken = async (userId, fcmToken) => {
  const [result] = await db.query('UPDATE users SET fcm_token = ? WHERE id = ?', [fcmToken, userId]);
  return result.affectedRows > 0;
};

const getFcmTokenByUserId = async (userId) => {
  const [rows] = await db.query('SELECT fcm_token FROM users WHERE id = ?', [userId]);
  return rows[0] ? rows[0].fcm_token : null;
};

const createUser = async (name, email, hashedPassword) => {
  const [result] = await db.query(
    'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
    [name, email, hashedPassword]
  );
  return result.insertId;
};

const getAllUsers = async () => {
  const [rows] = await db.query('SELECT id, name, email, created_at FROM users ORDER BY created_at DESC');
  return rows;
};

module.exports = {
  createUsersTable,
  findUserByEmail,
  findUserById,
  updateFcmToken,
  getFcmTokenByUserId,
  createUser,
  getAllUsers
};
