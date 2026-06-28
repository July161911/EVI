import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import bcrypt from 'bcryptjs';
import express from 'express';
import nodemailer from 'nodemailer';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dataFile = path.join(__dirname, 'data', 'users.json');
const port = Number(process.env.PORT || 3000);

const smtpHost = process.env.SMTP_HOST || '';
const smtpPort = Number(process.env.SMTP_PORT || 587);
const smtpUser = process.env.SMTP_USER || '';
const smtpPass = process.env.SMTP_PASS || '';
const smtpFrom = process.env.SMTP_FROM || smtpUser;
const defaultActivationBaseUrl =
  process.env.ACTIVATION_WEB_BASE_URL || `http://localhost:${port}/activate`;

function loadUsers() {
  if (!fs.existsSync(dataFile)) {
    return { users: [] };
  }
  return JSON.parse(fs.readFileSync(dataFile, 'utf8'));
}

function saveUsers(store) {
  fs.mkdirSync(path.dirname(dataFile), { recursive: true });
  fs.writeFileSync(dataFile, JSON.stringify(store, null, 2));
}

function findByUsername(store, username) {
  return store.users.find((user) => user.username === username);
}

function findByEmail(store, email) {
  return store.users.find((user) => user.email === email);
}

function findByToken(store, token) {
  return store.users.find((user) => user.confirmationToken === token);
}

function createTransporter() {
  if (!smtpHost || !smtpUser || !smtpPass) {
    return null;
  }
  return nodemailer.createTransport({
    host: smtpHost,
    port: smtpPort,
    secure: smtpPort === 465,
    auth: { user: smtpUser, pass: smtpPass },
  });
}

async function sendActivationEmail({ to, activationUrl }) {
  const transporter = createTransporter();
  const subject = 'EVI 账号激活';
  const text = [
    '请查收本邮件以激活您的 EVI 账号。',
    '',
    '请点击以下链接完成激活：',
    activationUrl,
    '',
    '激活成功后，请返回 EVI 应用登录。',
  ].join('\n');

  if (!transporter) {
    console.log('[dev] SMTP not configured. Activation link:', activationUrl);
    return;
  }

  await transporter.sendMail({
    from: smtpFrom,
    to,
    subject,
    text,
  });
}

function activationPage(success, message) {
  const title = success ? '账号已激活' : '激活失败';
  const color = success ? '#009999' : '#EC6602';
  return `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${title}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 0; background: #f7f7f7; color: #222; }
    main { max-width: 480px; margin: 48px auto; background: #fff; border-radius: 16px; padding: 32px 24px; box-shadow: 0 8px 24px rgba(0,0,0,.08); }
    h1 { margin: 0 0 12px; font-size: 24px; color: ${color}; }
    p { line-height: 1.6; margin: 0; }
  </style>
</head>
<body>
  <main>
    <h1>${title}</h1>
    <p>${message}</p>
  </main>
</body>
</html>`;
}

const app = express();
app.use(express.json());

app.post('/auth/register', async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const username = String(req.body.username || '').trim();
  const password = String(req.body.password || '');
  const requireEmailConfirmation = req.body.requireEmailConfirmation !== false;
  const activationLinkBaseUrl = String(
    req.body.activationLinkBaseUrl || defaultActivationBaseUrl,
  ).replace(/\/$/, '');

  if (!email || !username || !password) {
    return res.status(400).json({
      error: 'invalid_input',
      message: 'email, username, and password are required',
    });
  }

  const store = loadUsers();
  if (findByEmail(store, email)) {
    return res.status(409).json({
      error: 'email_taken',
      message: '该邮箱已被注册。',
    });
  }
  if (findByUsername(store, username)) {
    return res.status(409).json({
      error: 'username_taken',
      message: '该用户名已被使用。',
    });
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const confirmationToken = requireEmailConfirmation
    ? crypto.randomBytes(32).toString('hex')
    : null;

  store.users.push({
    email,
    username,
    passwordHash,
    confirmed: !requireEmailConfirmation,
    confirmationToken,
    createdAt: new Date().toISOString(),
  });
  saveUsers(store);

  if (requireEmailConfirmation && confirmationToken) {
    const activationUrl = `${activationLinkBaseUrl}?token=${confirmationToken}`;
    try {
      await sendActivationEmail({ to: email, activationUrl });
    } catch (error) {
      console.error('Failed to send activation email:', error);
      return res.status(500).json({
        error: 'server',
        message: '激活邮件发送失败，请稍后重试。',
      });
    }
  }

  return res.status(201).json({
    username,
    confirmed: !requireEmailConfirmation,
    status: requireEmailConfirmation ? 'pending_confirmation' : 'active',
  });
});

app.get('/activate', (req, res) => {
  const token = String(req.query.token || '').trim();
  if (!token) {
    return res
      .status(400)
      .send('激活链接无效或已过期。请重新注册或联系管理员。');
  }

  const store = loadUsers();
  const user = findByToken(store, token);
  if (!user) {
    return res
      .status(404)
      .send('激活链接无效或已过期。请重新注册或联系管理员。');
  }

  if (user.confirmed) {
    return res.send('您的账号已经激活，请返回 EVI 应用登录。');
  }

  user.confirmed = true;
  user.confirmationToken = null;
  user.activatedAt = new Date().toISOString();
  saveUsers(store);

  return res.send('账号激活成功！请返回 EVI 应用，使用您的用户名和密码登录。');
});

app.post('/auth/login', async (req, res) => {
  const username = String(req.body.username || '').trim();
  const password = String(req.body.password || '');

  if (!username || !password) {
    return res.status(400).json({
      error: 'invalid_input',
      message: 'username and password are required',
    });
  }

  const store = loadUsers();
  const user = findByUsername(store, username);
  if (!user) {
    return res.status(401).json({
      error: 'invalid_credentials',
      message: '用户名或密码错误。',
    });
  }

  const passwordOk = await bcrypt.compare(password, user.passwordHash);
  if (!passwordOk) {
    return res.status(401).json({
      error: 'invalid_credentials',
      message: '用户名或密码错误。',
    });
  }

  if (!user.confirmed) {
    return res.status(403).json({
      error: 'not_confirmed',
      message: '账号尚未激活，请查收邮箱并点击激活链接后再登录。',
      confirmed: false,
    });
  }

  return res.json({
    username: user.username,
    confirmed: true,
    token: crypto.randomBytes(24).toString('hex'),
  });
});

app.listen(port, () => {
  console.log(`EVI auth server listening on http://0.0.0.0:${port}`);
  if (!smtpHost) {
    console.log('SMTP not configured — activation links will be logged to console.');
  }
});
