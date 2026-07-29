export interface Env {
  OTP_KV: KVNamespace;
  RESEND_API_KEY: string;
  RESEND_FROM: string;
  FIREBASE_CLIENT_EMAIL: string;
  FIREBASE_PRIVATE_KEY: string;
}

const CODE_TTL_SECONDS = 600; // 10 minutes

function randomCode(): string {
  const n = crypto.getRandomValues(new Uint32Array(1))[0] % 1_000_000;
  return n.toString().padStart(6, '0');
}

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
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

      const code = randomCode();
      await env.OTP_KV.put(`otp:${email}`, code, { expirationTtl: CODE_TTL_SECONDS });

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

      const key = `otp:${email}`;
      const stored = await env.OTP_KV.get(key);
      if (!stored || stored !== code) {
        return json({ error: 'invalid-code' }, 401);
      }
      await env.OTP_KV.delete(key);

      const token = await createFirebaseCustomToken(env, uidForEmail(email));
      return json({ token });
    }

    return json({ error: 'not-found' }, 404);
  },
};
