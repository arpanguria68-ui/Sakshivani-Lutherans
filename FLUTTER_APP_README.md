# Sakshi Vani Flutter App

Offline-first Android Flutter application with Firebase sync (free-tier safe), built using your existing content assets and color system.

## What Is Implemented

- Material 3 app with terracotta seed palette and Hindi-first typography.
- Bottom-tab shell: Home, Songs, Bible, My Journey.
- Songs from `assets/Sakshivani_Unicode_Clean.db` with local search and song reader.
- Bible reader (Hindi + English) from local `bible_db.zip`.
- Catechism pages and quiz from bundled JSON assets.
- Journey tracking:
  - Prayer log (offline local DB + sync queue)
  - Reflections (offline local DB + sync queue)
  - Favorites (songs/verses with sync queue)
- Auth architecture with Riverpod state:
  - Local guest (offline)
  - Anonymous cloud session
  - Email login/signup
  - Forgot password
  - Google Sign-In
- Church Courtesy Mode:
  - Service-window prompt
  - Lower/restore volume
  - DND settings shortcut
  - Prompt cooldown
- Local notification scheduling:
  - Daily verse reminder
  - Church courtesy reminder

## Free-Tier Design Decisions

- Static content is bundled locally (no Firestore reads for Bible/songs/catechism).
- Firestore is used only for user-generated progress/favorites/reflections.
- No Cloud Functions are required in this implementation.
- Sync is queue-based and batched from local SQLite, minimizing write bursts.

## Project Structure Added

- `pubspec.yaml`
- `lib/main.dart`
- `lib/app.dart`
- `lib/core/*`
- `lib/data/*`
- `lib/features/*`
- `lib/services/*`
- `lib/shared/*`
- `lib/firebase_options.dart` (placeholder values)

## Firebase Setup (Spark Plan)

1. Create Firebase project on Spark (free).
2. Add Android app in Firebase console using your package ID.
3. Enable providers in Firebase Auth:
   - Email/Password
   - Google
   - Anonymous
4. Enable Firestore in production mode with rules below.
5. Replace placeholder values in `lib/firebase_options.dart`.
6. Add `android/app/google-services.json` once Android folder exists.

### Firestore Rules (recommended baseline)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## Run Instructions

This environment did not have Flutter installed, so platform folders were not generated here.

After installing Flutter locally:

1. Generate platform scaffolding if missing:
   - `flutter create --platforms=android --project-name sakshi_vani .`
2. Install dependencies:
   - `flutter pub get`
3. Run on device:
   - `flutter run -d android`

## Notes

- If Firebase placeholders stay unchanged, app runs in offline mode automatically.
- Google Sign-In requires SHA cert registration in Firebase for Android release/debug keys.
- For Play Store launch later, keep Spark until limits are genuinely reached.
