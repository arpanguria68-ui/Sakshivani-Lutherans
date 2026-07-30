# Play Store readiness — Legal & Data safety

## Public site (GitHub Pages — free)

After the Pages workflow runs once:

| Field | URL |
|-------|-----|
| Website | https://arpanguria68-ui.github.io/Sakshivani-Lutherans/ |
| Privacy policy | https://arpanguria68-ui.github.io/Sakshivani-Lutherans/privacy/ |
| Privacy (Hindi) | https://arpanguria68-ui.github.io/Sakshivani-Lutherans/privacy/?lang=hi |
| Terms of service | https://arpanguria68-ui.github.io/Sakshivani-Lutherans/terms/ |
| Terms (Hindi) | https://arpanguria68-ui.github.io/Sakshivani-Lutherans/terms/?lang=hi |

Source files live in `docs/`. Deploy workflow: `.github/workflows/github-pages.yml`.

**Enable once in GitHub:** Repo → Settings → Pages → Source: **GitHub Actions**.

In-app: **Settings → Legal** (EN / हिंदी toggle). Auth screen links to Terms + Privacy.

## Data safety form (checklist)

Declare approximately (confirm against live SDKs before submit):

- [ ] Email / phone — collected if user signs in — account management
- [ ] User IDs (Firebase UID) — account / sync
- [ ] App interactions — Analytics
- [ ] Crash logs — Crashlytics
- [ ] Device or other IDs — AdMob (if ads shown)
- [ ] Approximate location — optional weather
- [ ] Purchase history — via Google Play Billing
- [ ] Data encrypted in transit
- [ ] Users can request deletion (in-app Delete account / Reset)

## Regional coverage in documents

- **USA:** CCPA/CPRA disclosures, COPPA statement, no sale of personal info
- **EU/UK:** GDPR rights, UMP ad consent, supervisory authority
- **India:** DPDP Act 2023 rights, grievance contact (~30 days)

> These documents are application-specific templates reflecting current app behavior. Have them reviewed by counsel before relying on them as final legal advice.
