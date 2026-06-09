const jwt = require('jsonwebtoken');
const { getDatabase } = require('../models/db');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'mealplanner_super_jwt_secret_key_2026';

async function authMiddleware(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const token = authHeader.split(' ')[1];
    let decoded;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch (err) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const db = await getDatabase();
    
    // Check if session exists in DB and is not expired
    // Standard SQLite datetime("now") returns UTC, so we ensure our sessions are compared correctly.
    const session = await db.get(
      'SELECT * FROM UserSession WHERE user_id = ? AND jwt_token = ? AND expires_at > datetime("now")',
      [decoded.userId, token]
    );

    if (!session) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    req.user = { id: decoded.userId };
    req.token = token;
    next();
  } catch (error) {
    next(error);
  }
}

module.exports = authMiddleware;
