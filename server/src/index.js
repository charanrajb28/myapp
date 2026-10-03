require('dotenv').config();

const cors = require('cors');
const express = require('express');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const fs = require('fs');
const path = require('path');

const app = express();
const port = Number(process.env.PORT || 8082);

const localOrigins = new Set(
  (process.env.CLIENT_ORIGINS || 'http://localhost:5000,http://127.0.0.1:5000')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
);

app.use(cors({
  origin: (origin, callback) => {
    if (!origin || localOrigins.has(origin)) {
      return callback(null, true);
    }
    return callback(new Error('Origin is not allowed for local mail server.'));
  },
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'x-api-key'],
}));
app.use(express.json({ limit: '32kb' }));

function requiredEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function normalizePrivateKey(value) {
  let key = String(value).trim();
  if (key.startsWith('"') && key.endsWith('"')) {
    key = key.slice(1, -1);
  }
  key = key.replace(/\\n/g, '\n').replace(/\r/g, '');
  if (!key.includes('-----BEGIN PRIVATE KEY-----') ||
      !key.includes('-----END PRIVATE KEY-----')) {
    throw new Error('FIREBASE_PRIVATE_KEY is not a complete service-account private key.');
  }
  return key;
}

function getServiceAccount() {
  const filePath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH?.trim();
  if (filePath) {
    try {
      return JSON.parse(fs.readFileSync(path.resolve(filePath), 'utf8'));
    } catch {
      throw new Error('FIREBASE_SERVICE_ACCOUNT_PATH must point to a valid JSON key file.');
    }
  }

  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
  if (raw) {
    try {
      const parsed = JSON.parse(raw);
      if (parsed.project_id && parsed.client_email && parsed.private_key) {
        return parsed;
      }
    } catch {
      // Fall back to separate environment variables below when the JSON value
      // is not valid or is intentionally left as a placeholder.
    }
  }

  return {
    projectId: requiredEnv('FIREBASE_PROJECT_ID'),
    clientEmail: requiredEnv('FIREBASE_CLIENT_EMAIL'),
    privateKey: normalizePrivateKey(requiredEnv('FIREBASE_PRIVATE_KEY')),
  };
}

admin.initializeApp({
  credential: admin.credential.cert(getServiceAccount()),
});

const transporter = nodemailer.createTransport({
  host: requiredEnv('SMTP_HOST'),
  port: Number(process.env.SMTP_PORT || 465),
  secure: String(process.env.SMTP_SECURE || 'true').toLowerCase() === 'true',
  auth: {
    user: requiredEnv('SMTP_USER').toLowerCase(),
    // Gmail displays app passwords in groups; whitespace is not part of the
    // credential and must not be sent to the SMTP server.
    pass: requiredEnv('SMTP_PASSWORD').replace(/\s/g, ''),
  },
});

function requireApiKey(req, res, next) {
  const expected = requiredEnv('SERVER_API_KEY');
  if (req.get('x-api-key') !== expected) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

function validateEmail(value) {
  return typeof value === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());
}

function toCustomActionLink(firebaseLink, appUrl) {
  const generatedUrl = new URL(firebaseLink);
  const customUrl = new URL(`${appUrl.replace(/\/$/, '')}/auth/reset-password`);

  // Preserve Firebase's one-time action parameters (mode, oobCode, apiKey,
  // language, and continueUrl) while changing only the page that renders the
  // reset form.
  generatedUrl.searchParams.forEach((value, key) => {
    customUrl.searchParams.set(key, value);
  });

  return customUrl.toString();
}

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'aaroha-mail-server' });
});

app.post('/api/send-password-reset', requireApiKey, async (req, res) => {
  const email = String(req.body?.email || '').trim();
  if (!validateEmail(email)) {
    return res.status(400).json({ error: 'A valid email is required.' });
  }

  try {
    const appUrl = requiredEnv('PUBLIC_APP_URL').replace(/\/$/, '');
    const firebaseLink = await admin.auth().generatePasswordResetLink(email, {
      url: `${appUrl}/auth/reset-password`,
      handleCodeInApp: false,
    });
    const link = toCustomActionLink(firebaseLink, appUrl);

    await transporter.sendMail({
      from: `\"${process.env.MAIL_FROM_NAME || 'aaroha'}\" <${requiredEnv('SMTP_USER')}>`,
      to: email,
      subject: 'Reset your aaroha password',
      html: `
        <p>Hello,</p>
        <p>We received a request to reset your aaroha password.</p>
        <p><a href="${escapeHtml(link)}">Reset your password</a></p>
        <p>If you did not request this, you can ignore this email.</p>
        <p>Regards,<br><strong>aaroha Team</strong></p>
      `,
    });

    return res.json({ sent: true });
  } catch (error) {
    console.error('Password reset email failed:', error.message);
    return res.status(500).json({ error: 'Unable to send password reset email.' });
  }
});

app.post('/api/send-welcome', requireApiKey, async (req, res) => {
  const data = req.body || {};
  const email = String(data.email || '').trim();
  const accountType = String(data.accountType || 'student').toLowerCase();
  if (!validateEmail(email) || !data.name || !data.tempPassword || !['student', 'company'].includes(accountType)) {
    return res.status(400).json({ error: 'Email, name, and temporary password are required.' });
  }

  try {
    const appUrl = requiredEnv('PUBLIC_APP_URL').replace(/\/$/, '');
    const isStudent = accountType === 'student';
    await transporter.sendMail({
      from: `\"${process.env.MAIL_FROM_NAME || 'aaroha'}\" <${requiredEnv('SMTP_USER')}>`,
      to: email,
      subject: isStudent ? 'Welcome to aaroha' : 'Welcome to aaroha - Company Access',
      html: `
        <div style="font-family:Arial,sans-serif;color:#0F172A;max-width:640px">
          <h2 style="color:#2563EB">Welcome to aaroha, ${escapeHtml(data.name)}!</h2>
          <p>${isStudent ? 'Your student internship account has been created.' : 'Your company partner account has been created.'}</p>
          <p><strong>Portal:</strong> <a href="${escapeHtml(appUrl)}">Open aaroha</a></p>
          <p><strong>Login email:</strong> ${escapeHtml(email)}</p>
          <p><strong>Temporary password:</strong> ${escapeHtml(data.tempPassword)}</p>
          ${isStudent ? `
          <p><strong>Enrollment ID:</strong> ${escapeHtml(data.enrollmentId)}</p>
          <p><strong>College:</strong> ${escapeHtml(data.college)}</p>
          <p><strong>Department:</strong> ${escapeHtml(data.department)}</p>
          <p><strong>Semester:</strong> ${escapeHtml(data.semester)}</p>
          <p><strong>Phone:</strong> ${escapeHtml(data.phone)}</p>
          <p><strong>Parent/guardian:</strong> ${escapeHtml(data.parentName)}</p>
          <p><strong>Parent contact:</strong> ${escapeHtml(data.parentContact)}</p>
          <p><strong>Parent email:</strong> ${escapeHtml(data.parentEmail)}</p>` : `
          <p>Please sign in to manage internship postings and candidate applications.</p>`}
          <p style="font-size:12px;color:#64748B">Please change your password after your first sign-in.</p>
        </div>
      `,
    });

    return res.json({ sent: true });
  } catch (error) {
    console.error('Welcome email failed:', error.message);
    return res.status(500).json({ error: 'Unable to send welcome email.' });
  }
});


if (require.main === module) {
  app.listen(port, '127.0.0.1', () => {
    console.log(`aaroha mail server listening on port ${port}`);
  });
}

module.exports = app;
