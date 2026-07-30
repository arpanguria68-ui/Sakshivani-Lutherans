export interface Env {
  OTP_KV: KVNamespace;
  RESEND_API_KEY: string;
  RESEND_FROM: string;
  FIREBASE_CLIENT_EMAIL: string;
  FIREBASE_PRIVATE_KEY: string;
}

const CODE_TTL_SECONDS = 600; // 10 minutes
const SEND_LIMIT_PER_EMAIL = 3;
const SEND_LIMIT_PER_IP = 10;
const SEND_WINDOW_SECONDS = 3600;
const VERIFY_MAX_ATTEMPTS = 5;
const VERIFY_LOCKOUT_SECONDS = 900;

function randomCode(): string {
  const n = crypto.getRandomValues(new Uint32Array(1))[0] % 1_000_000;
  return n.toString().padStart(6, '0');
}

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function clientIp(request: Request): string {
  return request.headers.get('CF-Connecting-IP') ?? 'unknown';
}

/// Increment a KV counter with a TTL window. Returns false when the limit is
/// already reached (counter is not incremented further).
async function consumeRateLimit(
  kv: KVNamespace,
  key: string,
  limit: number,
  windowSeconds: number,
): Promise<boolean> {
  const raw = await kv.get(key);
  const count = raw ? Number.parseInt(raw, 10) : 0;
  if (count >= limit) {
    return false;
  }
  await kv.put(key, String(count + 1), { expirationTtl: windowSeconds });
  return true;
}

/// Deterministic Firebase uid for a given email, so repeat sign-ins with the
/// same address always land on the same account.
function uidForEmail(email: string): string {
  return `email:${email.toLowerCase()}`;
}

async function sendCodeEmail(env: Env, to: string, code: string): Promise<void> {
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: env.RESEND_FROM,
      to: [to],
      subject: 'Your Sakshi Vani sign-in code',
      html: `<p>Your verification code is <strong>${code}</strong>.</p><p>It expires in 10 minutes. If you didn't request this, ignore this email.</p>`,
    }),
  });
  if (!res.ok) {
    throw new Error(`Resend ${res.status}: ${await res.text()}`);
  }
}

function base64url(input: ArrayBuffer | string): string {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : new Uint8Array(input);
  let str = '';
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const contents = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  const der = Uint8Array.from(atob(contents), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    'pkcs8',
    der.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

/// A Firebase custom token is just a self-contained RS256 JWT signed by the
/// service account — the client SDK's `signInWithCustomToken` verifies it
/// against that same service account, no extra network round trip needed.
async function createFirebaseCustomToken(env: Env, uid: string): Promise<string> {
  const header = { alg: 'RS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: env.FIREBASE_CLIENT_EMAIL,
    sub: env.FIREBASE_CLIENT_EMAIL,
    aud: 'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
    iat: now,
    exp: now + 3600,
    uid,
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(payload))}`;
  const key = await importPrivateKey(env.FIREBASE_PRIVATE_KEY);
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  return `${unsigned}.${base64url(signature)}`;
}

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }

    const url = new URL(request.url);

    if (request.method === 'POST' && url.pathname === '/send-code') {
      const body = await request
        .json<{ email?: string }>()
        .catch((): { email?: string } => ({}));
      const email = body.email?.trim().toLowerCase();
      if (!email || !isValidEmail(email)) {
        return json({ error: 'invalid-email' }, 400);
      }

      const ip = clientIp(request);
      const emailAllowed = await consumeRateLimit(
        env.OTP_KV,
        `rate:send:email:${email}`,
        SEND_LIMIT_PER_EMAIL,
        SEND_WINDOW_SECONDS,
      );
      const ipAllowed = await consumeRateLimit(
        env.OTP_KV,
        `rate:send:ip:${ip}`,
        SEND_LIMIT_PER_IP,
        SEND_WINDOW_SECONDS,
      );
      if (!emailAllowed || !ipAllowed) {
        return json({ error: 'rate-limited' }, 429);
      }

      const code = randomCode();
      await env.OTP_KV.put(`otp:${email}`, code, { expirationTtl: CODE_TTL_SECONDS });
      // Reset verify-attempt counter whenever a fresh code is issued.
      await env.OTP_KV.delete(`verify-attempts:${email}`);

      try {
        await sendCodeEmail(env, email, code);
      } catch (e) {
        return json({ error: 'send-failed', message: String(e) }, 502);
      }
      return json({ ok: true });
    }

    if (request.method === 'POST' && url.pathname === '/verify-code') {
      const body = await request
        .json<{ email?: string; code?: string }>()
        .catch((): { email?: string; code?: string } => ({}));
      const email = body.email?.trim().toLowerCase();
      const code = body.code?.trim();
      if (!email || !code) {
        return json({ error: 'invalid-request' }, 400);
      }

      const attemptsKey = `verify-attempts:${email}`;
      const attemptsRaw = await env.OTP_KV.get(attemptsKey);
      const attempts = attemptsRaw ? Number.parseInt(attemptsRaw, 10) : 0;
      if (attempts >= VERIFY_MAX_ATTEMPTS) {
        return json({ error: 'too-many-attempts' }, 429);
      }

      const key = `otp:${email}`;
      const stored = await env.OTP_KV.get(key);
      if (!stored || stored !== code) {
        await env.OTP_KV.put(attemptsKey, String(attempts + 1), {
          expirationTtl: VERIFY_LOCKOUT_SECONDS,
        });
        return json({ error: 'invalid-code' }, 401);
      }
      await env.OTP_KV.delete(key);
      await env.OTP_KV.delete(attemptsKey);

      const token = await createFirebaseCustomToken(env, uidForEmail(email));
      return json({ token });
    }

    return json({ error: 'not-found' }, 404);
  },
};
