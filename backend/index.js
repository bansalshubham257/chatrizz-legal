require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || crypto.randomBytes(64).toString('hex');
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || crypto.randomBytes(32).toString('hex');

if (!GOOGLE_CLIENT_ID) {
  console.error('GOOGLE_CLIENT_ID environment variable is required');
  process.exit(1);
}

const pool = new Pool({
  host: process.env.DB_HOST || 'switchback.proxy.rlwy.net',
  port: parseInt(process.env.DB_PORT || '22297'),
  database: process.env.DB_NAME || 'chatrizz_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
});

if (!pool.password) {
  console.error('DB_PASSWORD environment variable is required');
  process.exit(1);
}

const googleClient = new OAuth2Client(GOOGLE_CLIENT_ID);

function encrypt(text) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-gcm', Buffer.from(ENCRYPTION_KEY, 'hex').subarray(0, 32), iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  const authTag = cipher.getAuthTag().toString('hex');
  return `${iv.toString('hex')}:${authTag}:${encrypted}`;
}

function decrypt(encryptedData) {
  try {
    const parts = encryptedData.split(':');
    if (parts.length !== 3) return null;
    const iv = Buffer.from(parts[0], 'hex');
    const authTag = Buffer.from(parts[1], 'hex');
    const encrypted = parts[2];
    const decipher = crypto.createDecipheriv('aes-256-gcm', Buffer.from(ENCRYPTION_KEY, 'hex').subarray(0, 32), iv);
    decipher.setAuthTag(authTag);
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch {
    return null;
  }
}

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  try {
    const token = authHeader.split(' ')[1];
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

app.post('/auth/google', async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    const googleId = payload['sub'];
    const email = payload['email'];
    const displayName = payload['name'];

    const encryptedData = encrypt(JSON.stringify({ email, displayName, googleId }));

    const result = await pool.query(
      `INSERT INTO chatrizz.users (google_id, email, display_name, encrypted_data, credits)
       VALUES ($1, $2, $3, $4, 10)
       ON CONFLICT (google_id)
       DO UPDATE SET email = EXCLUDED.email, display_name = EXCLUDED.display_name,
                     encrypted_data = EXCLUDED.encrypted_data, updated_at = NOW()
       RETURNING id, google_id, credits, created_at`,
      [googleId, email, displayName, encryptedData]
    );

    const user = result.rows[0];
    const token = jwt.sign(
      { userId: user.id, googleId: user.google_id },
      JWT_SECRET,
      { expiresIn: '90d' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        credits: user.credits,
        createdAt: user.created_at,
      },
    });
  } catch (err) {
    console.error('Auth error:', err);
    res.status(401).json({ error: 'Authentication failed' });
  }
});

app.get('/credits', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT credits FROM chatrizz.users WHERE id = $1 AND deleted_at IS NULL',
      [req.user.userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json({ credits: result.rows[0].credits });
  } catch (err) {
    console.error('Get credits error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/credits/deduct', authMiddleware, async (req, res) => {
  const { amount } = req.body;
  if (!amount || amount < 1) {
    return res.status(400).json({ error: 'Invalid amount' });
  }
  try {
    const result = await pool.query(
      `UPDATE chatrizz.users
       SET credits = credits - $1, updated_at = NOW()
       WHERE id = $2 AND deleted_at IS NULL AND credits >= $1
       RETURNING credits`,
      [amount, req.user.userId]
    );
    if (result.rows.length === 0) {
      return res.status(400).json({ error: 'Insufficient credits' });
    }
    res.json({ credits: result.rows[0].credits });
  } catch (err) {
    console.error('Deduct credits error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/credits/add', authMiddleware, async (req, res) => {
  const { amount } = req.body;
  if (!amount || amount < 1) {
    return res.status(400).json({ error: 'Invalid amount' });
  }
  try {
    const result = await pool.query(
      `UPDATE chatrizz.users
       SET credits = credits + $1, updated_at = NOW()
       WHERE id = $2 AND deleted_at IS NULL
       RETURNING credits`,
      [amount, req.user.userId]
    );
    res.json({ credits: result.rows[0].credits });
  } catch (err) {
    console.error('Add credits error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.delete('/user', authMiddleware, async (req, res) => {
  try {
    await pool.query(
      `UPDATE chatrizz.users
       SET deleted_at = NOW(), email = NULL, display_name = NULL, encrypted_data = NULL, credits = 0
       WHERE id = $1`,
      [req.user.userId]
    );
    res.json({ message: 'Account deleted' });
  } catch (err) {
    console.error('Delete user error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`ChatRizz backend running on port ${PORT}`);
});
