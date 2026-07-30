# Sakshi Vani Privacy Policy

**Last updated:** July 2026  
**Languages:** English (this document) · [हिंदी](PRIVACY_HI.md)  
**Also see:** [Terms & Conditions](TERMS.md)

Sakshi Vani (“the app”, “we”) is an offline-first Lutheran hymns and Bible study app. This policy explains what data we collect, why, how long we keep it, and your choices — including requirements relevant to the **United States**, the **European Economic Area (EEA) / UK**, and **India**.

---

## 1. Data we collect

### 1.1 On your device (local only)
- Reading progress, prayer logs, favorites, and reflections
- App preferences (theme, TTS engine, reminders, reader settings)
- Optional manual city for weather
- Downloaded Bible archive (stored in app documents after first download)

This data stays on your device unless you sign in and enable cloud sync.

### 1.2 When you sign in (optional)
If you create an account (email/password, Google, phone OTP, or email OTP), we store under your user ID in **Firebase**:
- Account identifiers (e.g. UID, email or phone as provided by the auth provider)
- Favorites, reflections, and prayer logs you choose to sync

We use **Firebase Authentication** to manage your account. We do **not** sell your personal data.

### 1.3 Analytics and crash reports
When Firebase is enabled, we collect:
- Anonymized / pseudonymous usage events (e.g. song opened, quiz completed, daily verse viewed) via **Firebase Analytics**
- Crash and diagnostic reports via **Firebase Crashlytics**

Purpose: improve stability and understand feature usage.

### 1.4 Ads
The free tier may show **Google AdMob** ads. AdMob may collect device advertising identifiers and similar data per [Google’s privacy policy](https://policies.google.com/privacy). You can remove ads via the in-app purchase.

In the EEA/UK, consent for personalized ads (where required) is requested through Google’s **UMP** consent form.

### 1.5 Location
Weather uses **coarse location** only when you allow it, via **Open-Meteo** (coordinates sent to fetch forecast). You can enter a manual city instead. We do not continuously track your location in the background for marketing.

### 1.6 Email OTP
If you use email code sign-in, a short-lived OTP is sent via our **Cloudflare Worker**. Codes expire (typically within 10 minutes). Rate limits apply to reduce abuse. OTPs are not kept as long-term profile data.

### 1.7 Data we do **not** collect intentionally
- Payment card numbers (handled by Google Play)
- Precise continuous GPS trails for advertising
- Contacts, SMS content, or microphone audio for our own servers (TTS runs on-device / system engines)

---

## 2. Why we process data (purposes)

| Purpose | Examples | Legal basis (EEA/UK) |
|--------|----------|----------------------|
| Provide the App | Local storage, Bible download, reminders | Contract / legitimate interests |
| Optional account & sync | Firebase Auth + Firestore | Contract / consent |
| Security & abuse prevention | OTP rate limits, auth | Legitimate interests / legal obligation |
| Analytics & crash fixing | Analytics, Crashlytics | Legitimate interests / consent where required |
| Ads | AdMob | Consent (EEA) / legitimate interests where allowed |
| Weather | Location or city | Consent (permission) / legitimate interests |

---

## 3. Sharing

We share data only with processors needed to run the App (Google Firebase/AdMob/Play, Cloudflare for OTP, Open-Meteo for weather) under their terms. We do not sell personal information. We may disclose data if required by law or to protect users’ safety and our rights.

International transfers (e.g. to Google infrastructure) may occur; providers typically use Standard Contractual Clauses or equivalent safeguards where required.

---

## 4. Retention and deletion

- **Local data:** remains until you clear app data, uninstall, or use **Reset app**.
- **Cloud sync data:** retained while your account exists.
- **Delete account** (in Settings): removes your Firebase Auth user and associated cloud data we control.
- **Analytics/crash:** retained per Firebase defaults / our project settings.
- **Email OTPs:** short-lived; not stored as long-term PII.

---

## 5. Your choices & rights

### All users
- Use the App without signing in for core offline features
- Deny location permission; use manual city
- Disable reminders in Settings
- Reset local data or delete account
- Remove ads via purchase
- Review this policy and the Terms in Settings → Legal

### 5.1 United States (including California CCPA/CPRA)
- Right to know categories of personal information collected
- Right to delete (subject to exceptions)
- Right to correct inaccurate information
- Right to opt out of “sale” / “sharing” — **we do not sell** your personal information; ad identifiers may be processed by Google under AdMob
- Non-discrimination for exercising privacy rights
- **COPPA:** not directed to children under 13; we do not knowingly collect under-13 data without parental consent

To exercise rights: use in-app delete/reset or contact us via the Play Store listing / repository.

### 5.2 EEA / UK (GDPR / UK GDPR)
You may have rights to:
- Access, rectification, erasure
- Restriction or objection to processing
- Data portability
- Withdraw consent (where processing is consent-based) without affecting prior lawful processing
- Lodge a complaint with your supervisory authority

Contact us to exercise these rights. We respond within one month where required (extendable for complex requests).

### 5.3 India (DPDP Act, 2023)
As applicable, you may:
- Seek access to and correction of your personal data
- Request erasure / withdrawal of consent (subject to lawful retention needs)
- Nominate (where applicable under rules) and raise a grievance with us

We aim to address grievances within a reasonable time (generally within **30 days** where required). Contact via Play Store listing or repository issues.

---

## 6. Children’s privacy

The App is for a **general audience**. We do not knowingly collect personal information from children under 13 (US) / under the applicable digital age of consent in the EEA (often 13–16) / under 18 in India where parental consent is required for certain processing — without appropriate consent. If you believe a child provided data improperly, contact us to delete it.

---

## 7. Security

We use industry-standard providers (Firebase, HTTPS) and limit cloud data to what sync needs. No method of transmission or storage is 100% secure.

---

## 8. Play Store Data safety (summary for developers / reviewers)

Declare in Play Console approximately as follows (verify against current SDK versions):

| Data type | Collected? | Shared? | Purpose |
|-----------|------------|---------|---------|
| Email / phone | Yes (if user signs in) | With auth provider | Account |
| User IDs | Yes (Firebase UID) | Google Firebase | Account / sync |
| App interactions | Yes (Analytics) | Google | Analytics |
| Crash logs | Yes | Google | App functionality |
| Device / advertising IDs | Yes (if ads shown) | Google AdMob | Advertising |
| Approximate location | Optional | Open-Meteo | App functionality (weather) |
| In-app purchase history | Via Play | Google Play | App functionality |

**Data encrypted in transit:** yes (HTTPS).  
**Users can request deletion:** yes (Delete account / Reset).

---

## 9. Contact

For privacy questions, open an issue on the project repository or use the contact email on the Google Play Store listing.

---

## 10. Changes

We may update this policy. The “Last updated” date will change. Continued use after changes constitutes acceptance where permitted by law; where required, we will seek fresh consent.
