# Sakshi Vani — Email OTP Worker

Sends a 6-digit sign-in code by email (via Resend) and, once the user enters
it correctly, mints a Firebase custom token so the app can sign them in
without any phone number or SMS cost.

## One-time setup

```bash
cd cloudflare/email-otp-worker
npm install
npx wrangler login          # opens a browser, log into your Cloudflare account
npx wrangler kv namespace create OTP_KV
```

The last command prints an `id`. Copy it into `wrangler.toml`, replacing
`REPLACE_WITH_KV_NAMESPACE_ID`.

## Secrets

Run each of these — they prompt for the value on stdin, so nothing is ever
written to disk or shell history:

```bash
npx wrangler secret put RESEND_API_KEY
# paste the Resend API key (starts with re_) when prompted

npx wrangler secret put RESEND_FROM
# e.g. "Sakshi Vani <onboarding@resend.dev>" for testing, or an address on
# a domain you've verified in Resend for production (Resend requires a
# verified domain to send to arbitrary real users — the onboarding@resend.dev
# sender only works for your own Resend account email during development)

npx wrangler secret put FIREBASE_CLIENT_EMAIL
# the "client_email" field from a Firebase service account JSON
# (Firebase console -> Project settings -> Service accounts -> Generate new private key)

npx wrangler secret put FIREBASE_PRIVATE_KEY
# the "private_key" field from that same JSON, including the
# -----BEGIN PRIVATE KEY-----...-----END PRIVATE KEY----- wrapper.
# NEVER paste this key anywhere except this prompt — it grants full
# admin access to the Firebase project (bypasses all security rules).
```

## Deploy

```bash
npx wrangler deploy
```

This prints the live URL, something like:
`https://sakshivani-email-otp.<your-subdomain>.workers.dev`

Put that URL into `lib/core/constants/app_constants.dart` →
`emailOtpWorkerUrl` in the Flutter project.

## API

- `POST /send-code` `{ "email": "user@example.com" }` → `{ "ok": true }`
- `POST /verify-code` `{ "email": "...", "code": "123456" }` → `{ "token": "<firebase custom token>" }`

The app calls `FirebaseAuth.instance.signInWithCustomToken(token)` with that
token to complete sign-in.

## Known limitation

Signing in via a custom token always creates/uses a fixed uid derived from
the email — it does **not** link to an existing anonymous session the way
Google/Phone sign-in do. A user who was anonymous and then verifies by email
will get a *new* account; their previous anonymous-session local data stays
on-device but won't carry over to the email account's cloud data.
