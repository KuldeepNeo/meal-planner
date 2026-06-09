const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getDatabase } = require('../models/db');
const { validate, schemas } = require('../middleware/validate');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'mealplanner_super_jwt_secret_key_2026';

// POST /api/auth/register
router.post('/register', validate(schemas.register), async (req, res, next) => {
  try {
    const { name, email, password } = req.body;
    const db = await getDatabase();

    // Check if email already exists
    const existingUser = await db.get('SELECT id FROM User WHERE email = ?', [email]);
    if (existingUser) {
      return res.status(409).json({ error: 'Email already exists' });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);
    const now = new Date().toISOString();

    const result = await db.run(
      'INSERT INTO User (name, email, password_hash, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
      [name, email, passwordHash, 'ACTIVE', now, now]
    );

    return res.status(201).json({
      userId: result.lastID,
      message: 'Registration successful'
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/auth/login
router.post('/login', validate(schemas.login), async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const db = await getDatabase();

    // Find user
    const user = await db.get('SELECT * FROM User WHERE email = ?', [email]);
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Compare password
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate tokens
    const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '15m' });
    const refreshToken = jwt.sign({ userId: user.id }, JWT_SECRET + '_refresh', { expiresIn: '7d' });

    // Save session in DB
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString(); // 15 mins
    const now = new Date().toISOString();

    await db.run(
      'INSERT INTO UserSession (user_id, jwt_token, refresh_token, expires_at, created_at) VALUES (?, ?, ?, ?, ?)',
      [user.id, token, refreshToken, expiresAt, now]
    );

    return res.status(200).json({
      token,
      refreshToken,
      userId: user.id
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/auth/password-reset-request
router.post('/password-reset-request', validate(schemas.passwordResetRequest), async (req, res, next) => {
  try {
    const { email } = req.body;
    const db = await getDatabase();

    // Find user
    const user = await db.get('SELECT id FROM User WHERE email = ?', [email]);
    if (!user) {
      return res.status(404).json({ error: 'User Not Found' });
    }

    // Generate reset token
    const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '1h' });
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString(); // 1 hour

    await db.run(
      'INSERT INTO PasswordResetToken (user_id, token, expires_at) VALUES (?, ?, ?)',
      [user.id, token, expiresAt]
    );

    // In a real application, email token link here.
    console.log(`Password reset link generated: http://localhost:${process.env.PORT || 5003}/api/auth/password-reset?token=${token}`);

    return res.status(200).json({
      message: 'Password reset link sent'
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/auth/password-reset
router.post('/password-reset', validate(schemas.passwordReset), async (req, res, next) => {
  try {
    const { token, newPassword } = req.body;
    const db = await getDatabase();

    // Check token
    const resetToken = await db.get(
      'SELECT * FROM PasswordResetToken WHERE token = ? AND expires_at > datetime("now") AND used_at IS NULL',
      [token]
    );

    if (!resetToken) {
      return res.status(400).json({ error: 'Invalid Token' });
    }

    // Hash new password
    const passwordHash = await bcrypt.hash(newPassword, 10);
    const now = new Date().toISOString();

    // Begin transaction
    await db.exec('BEGIN TRANSACTION;');
    try {
      // Update user password
      await db.run(
        'UPDATE User SET password_hash = ?, updated_at = ? WHERE id = ?',
        [passwordHash, now, resetToken.user_id]
      );

      // Mark token as used
      await db.run(
        'UPDATE PasswordResetToken SET used_at = ? WHERE id = ?',
        [now, resetToken.id]
      );

      // Invalidate all active sessions for this user
      await db.run('DELETE FROM UserSession WHERE user_id = ?', [resetToken.user_id]);

      await db.exec('COMMIT;');
    } catch (err) {
      await db.exec('ROLLBACK;');
      throw err;
    }

    return res.status(200).json({
      message: 'Password updated'
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
