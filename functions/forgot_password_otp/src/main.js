import crypto from 'node:crypto';
import sdk from 'node-appwrite';

const OTP_PREFS_KEY = 'password_reset_otp';
const OTP_LENGTH = 6;
const OTP_EXPIRE_MINUTES = 10;
const MAX_ATTEMPTS = 5;

function getApiKey(req) {
  return req.headers['x-appwrite-key'] || req.headers['X-Appwrite-Key'];
}

function getClient(req) {
  const apiKey = getApiKey(req);

  if (!apiKey) {
    throw new Error('Missing dynamic Appwrite function API key.');
  }

  return new sdk.Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(apiKey);
}

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function generateOtp() {
  return crypto.randomInt(0, 10 ** OTP_LENGTH).toString().padStart(OTP_LENGTH, '0');
}

function hashOtp(email, otp) {
  const secret = process.env.OTP_HASH_SECRET || 'change-me-before-production';
  return crypto
    .createHash('sha256')
    .update(`${secret}:${normalizeEmail(email)}:${otp}`)
    .digest('hex');
}

async function findUserByEmail(users, email) {
  const result = await users.list({
    queries: [sdk.Query.equal('email', [normalizeEmail(email)])],
  });

  return result.users[0] || null;
}

function buildOtpPrefs(email, otp) {
  return {
    hash: hashOtp(email, otp),
    expiresAt: new Date(Date.now() + OTP_EXPIRE_MINUTES * 60 * 1000).toISOString(),
    attempts: 0,
  };
}

async function sendOtpEmail(messaging, userId, otp) {
  return messaging.createEmail({
    messageId: sdk.ID.unique(),
    users: [userId],
    subject: 'Your password reset OTP',
    content: `
      <div style="font-family: Arial, sans-serif; line-height: 1.6;">
        <h2>Password Reset OTP</h2>
        <p>Use the OTP below to reset your password.</p>
        <p style="font-size: 28px; font-weight: bold; letter-spacing: 6px;">${otp}</p>
        <p>This OTP will expire in ${OTP_EXPIRE_MINUTES} minutes.</p>
        <p>If you did not request this, you can ignore this email.</p>
      </div>
    `,
    html: true,
  });
}

async function handleRequestOtp({ users, messaging, email, log }) {
  const normalizedEmail = normalizeEmail(email);
  const user = await findUserByEmail(users, normalizedEmail);

  if (!user) {
    log(`OTP requested for unknown email: ${normalizedEmail}`);
    return {
      success: true,
      message: 'If an account exists for this email, an OTP has been sent.',
    };
  }

  const otp = generateOtp();
  const nextPrefs = {
    ...(user.prefs || {}),
    [OTP_PREFS_KEY]: buildOtpPrefs(normalizedEmail, otp),
  };

  await users.updatePrefs({
    userId: user.$id,
    prefs: nextPrefs,
  });

  await sendOtpEmail(messaging, user.$id, otp);

  return {
    success: true,
    message: 'If an account exists for this email, an OTP has been sent.',
  };
}

async function handleResetPassword({ users, email, otp, password }) {
  const normalizedEmail = normalizeEmail(email);
  const user = await findUserByEmail(users, normalizedEmail);

  if (!user) {
    return {
      success: false,
      message: 'Invalid OTP or email.',
      code: 400,
    };
  }

  const currentPrefs = user.prefs || {};
  const otpPrefs = currentPrefs[OTP_PREFS_KEY];

  if (!otpPrefs) {
    return {
      success: false,
      message: 'No OTP request found. Please request a new OTP.',
      code: 400,
    };
  }

  const expiresAt = new Date(otpPrefs.expiresAt || 0);
  if (Number.isNaN(expiresAt.getTime()) || expiresAt.getTime() < Date.now()) {
    delete currentPrefs[OTP_PREFS_KEY];
    await users.updatePrefs({ userId: user.$id, prefs: currentPrefs });
    return {
      success: false,
      message: 'OTP expired. Please request a new one.',
      code: 400,
    };
  }

  const nextAttempts = Number(otpPrefs.attempts || 0) + 1;
  const expectedHash = hashOtp(normalizedEmail, otp);

  if (expectedHash !== otpPrefs.hash) {
    currentPrefs[OTP_PREFS_KEY] = {...otpPrefs, attempts: nextAttempts};
    if (nextAttempts >= MAX_ATTEMPTS) {
      delete currentPrefs[OTP_PREFS_KEY];
    }
    await users.updatePrefs({ userId: user.$id, prefs: currentPrefs });

    return {
      success: false,
      message: 'Invalid OTP. Please try again.',
      code: 400,
    };
  }

  await users.updatePassword({
    userId: user.$id,
    password,
  });

  delete currentPrefs[OTP_PREFS_KEY];
  await users.updatePrefs({
    userId: user.$id,
    prefs: currentPrefs,
  });

  return {
    success: true,
    message: 'Password updated successfully.',
  };
}

export default async ({ req, res, log, error }) => {
  try {
    const body = req.bodyJson || JSON.parse(req.bodyText || '{}');
    const action = body.action;
    const email = normalizeEmail(body.email);
    const otp = String(body.otp || '').trim();
    const password = String(body.password || '');

    const client = getClient(req);
    const users = new sdk.Users(client);
    const messaging = new sdk.Messaging(client);

    if (action === 'request_otp') {
      if (!email) {
        return res.json({ success: false, message: 'Email is required.' }, 400);
      }

      const result = await handleRequestOtp({ users, messaging, email, log });
      return res.json(result, 200);
    }

    if (action === 'reset_password') {
      if (!email || !otp || password.length < 8) {
        return res.json(
          {
            success: false,
            message: 'Email, OTP, and a password of at least 8 characters are required.',
          },
          400,
        );
      }

      const result = await handleResetPassword({
        users,
        email,
        otp,
        password,
      });
      return res.json(result, result.code || 200);
    }

    return res.json({ success: false, message: 'Unsupported action.' }, 400);
  } catch (err) {
    error(err.message || String(err));
    return res.json(
      {
        success: false,
        message: err.message || 'Unexpected function error.',
      },
      500,
    );
  }
};
