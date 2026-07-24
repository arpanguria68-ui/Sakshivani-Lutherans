# Sakshi Vani — Production Android Plan (Flutter track)

> Status: **PLAN — awaiting review before any code is written.**
> Target: ship `lib/` Flutter app as a production, Play-Store-ready Android app.
> Author: senior-engineer review of current `lib/` tree (50 dart files) + assets.

---

## 0. Decisions locked (from you)

| Decision | Choice |
|---|---|
| App track | **Finish Flutter native** (`lib/`) → production Android. PWA/RN frozen. |
| Search | **Enhanced lexical** — FTS5 + BM25 ranking + Hindi phonetic + synonyms + typo tolerance. No ML model. |
| Mode | Plan first, you approve, then I build. |

Still need your input on a few items — see **§9 Open questions**. Everything else has a sane default chosen.

---

## 1. Current state — honest audit

**Architecture (good, keep it):** Riverpod + go_router + Material 3, offline-first SQLite, sync-queue to Firestore. Clean feature-first layout.

**Blockers to "production Android":**

| # | Problem | File / evidence |
|---|---|---|
| B1 | **No `android/` folder** — app literally cannot build to Android. | repo root: no `android/`, no `ios/` |
| B2 | `firebase_options.dart` holds **placeholder values**; no `google-services.json`. | `FLUTTER_APP_README.md`, `lib/firebase_options.dart` |
| B3 | **Search is naive `LIKE '%q%'`**, no ranking. | `content_repository.dart` `getSongs()` |
| B4 | **Bible search is full-scan O(verses)** every keystroke, loads whole Bible JSON to RAM. | `bible_repository.dart` `search()` |
| B5 | **Reader has no TTS at all** in Flutter (only font ±). | `song_reader_screen.dart` |
| B6 | **No e-ink / reading mode.** | — |
| B7 | **No weather, no geolocation.** | — |
| B8 | **Planner is thin** — prayer log + reflections only. | `journey_tab.dart` |
| B9 | Song lyrics forced `TextAlign.center`; Devanagari matra/alignment unverified. | `song_reader_screen.dart` |
| B10 | Deps outdated; `flutter_markdown` discontinued; 33 packages behind. | `flutter_setup.log` |
| B11 | No app icon / splash / adaptive icon pipeline. | — |
| B12 | No tests, no CI, no crash reporting. | `lib/` has no `test/` usage |

---

## 2. Phased roadmap

Six phases. Each is independently shippable/reviewable. Rough effort in dev-days assuming I do the work and you test on-device.

### Phase 1 — Make it build & run on Android  *(foundation, ~1–2 d)*
- `flutter create . --platforms=android --org com.sakshivani` to generate `android/` without touching `lib/`.
- Set `applicationId`, min SDK 23, target latest, versionCode/Name.
- Wire real Firebase: run `flutterfire configure`, drop real `google-services.json`, replace `firebase_options.dart`. **(needs your Firebase project — §9 Q1)**
- Android 13+ runtime notification permission (`POST_NOTIFICATIONS`) + exact-alarm handling for the scheduler.
- Permissions in manifest: INTERNET, POST_NOTIFICATIONS, (weather →) ACCESS_COARSE_LOCATION.
- Bump `flutter_local_notifications`, migrate `flutter_markdown` → `flutter_markdown_plus`, resolve breaking deps.
- Verify assets bundle (songs `.db`, `bible_db.zip`, `catechism.json`, `quiz_data.json`, fonts) load on a real device.
- **Exit criteria:** signed debug APK installs and runs on a physical Android phone; daily verse, songs, bible, catechism, quiz all load.

### Phase 2 — Enhanced search + ranking  *(the headline feature, ~3–4 d)*
See **§3** for full design. Applies to **both** the Songs search bar and the Global search bar, plus a new ranked Bible search.
- Build an FTS5 index at first launch (writable app DB), since the shipped songs `.db` is read-only.
- BM25 base ranking + field boosts (title ≫ lyrics) + phonetic + synonym expansion + typo tolerance + prefix (autocomplete).
- Debounced input, highlighted matches, "did you mean", category/first-letter filters, recent searches.
- **Exit criteria:** searching "yeeshu" / "यीशू" / a misspelling / an English transliteration all return the right hymns, ranked, <50 ms.

### Phase 3 — Reader, TTS & E-ink mode  *(~3 d)*
See **§4**.
- Add `flutter_tts` (offline Android TTS engine). Play / pause / stop, per-line highlight, speed, Hindi voice selection.
- Reading settings sheet: font size (exists), line height, letter/word spacing, serif/sans toggle, alignment (fix B9).
- **E-ink mode:** pure-grayscale high-contrast theme, no gradients/shadows/animations, paginated (tap-to-turn) instead of scroll, sepia option. Toggle persists.
- Apply the reader consistently across Songs, Catechism, Bible.
- **Exit criteria:** a hymn reads aloud in Hindi with line highlight; e-ink mode looks like paper and disables all motion.

### Phase 4 — Enhanced planner  *(~3–4 d)*
See **§5**.
- Bible reading plans (e.g. 1-year, Gospels-in-40-days, custom range) with daily checkoff + progress ring.
- Prayer planner: scheduled prayer times, custom reminders, prayer intentions list.
- Habit/streak calendar (heatmap) — extends existing streak stat.
- Unified "Today" plan card on Home: today's verse + reading + prayer + weather.
- Custom local-notification scheduling UI (currently hardcoded 06:30 / Sun 09:15).
- **Exit criteria:** user can start a reading plan, get daily reminders, check off, and see streak heatmap.

### Phase 5 — Live weather + interactive extras  *(~2–3 d)*
See **§6**.
- Open-Meteo (free, no API key) + `geolocator`; graceful offline fallback + manual city.
- Home weather widget; optional "weather-aware" verse/prayer prompt.
- Interactive extras (pick from §6 menu): verse-of-the-day share cards (image), quiz streaks & badges, audio playlists of hymns, bookmarking + highlights in Bible, daily devotional widget (home-screen), dark/light/e-ink quick toggle.
- **Exit criteria:** live local weather on Home; at least 2 interactive features shipped.

### Phase 6 — Production hardening & release  *(~2–3 d)*
- App icon + adaptive icon + splash (`flutter_launcher_icons`, `flutter_native_splash`). **(needs brand art — §9 Q4)**
- Crashlytics + basic analytics (free tier).
- Error/empty/loading states everywhere; offline banners.
- Perf pass (search, bible load, image cache), memory, jank check.
- Accessibility: TalkBack labels, contrast, min tap targets.
- Firestore security rules (baseline already in README), data-safety form, privacy policy.
- Signed **AAB**, versioning, Play Console listing, internal-testing track.
- Minimal test suite (search ranking unit tests, repo tests) + GitHub Actions build.
- **Exit criteria:** signed AAB uploaded to Play internal testing.

**Total rough effort: ~14–19 dev-days**, phased so you can ship/stop after any phase.

---

## 3. Search design (Phase 2 detail)

**Problem:** `LIKE '%q%'` — no ranking, case/diacritic naive, no typo/phonetic/transliteration handling. Bible search re-scans the whole book each keystroke.

**Approach — layered lexical, all on-device, no model:**

1. **FTS5 index (built at first run).**
   Shipped `Sakshivani_Unicode_Clean.db` is read-only → on first launch create a writable `search_index.db`:
   ```sql
   CREATE VIRTUAL TABLE songs_fts USING fts5(
     title, lyrics, category, reference,
     tokenize = 'unicode61 remove_diacritics 2'
   );
   ```
   Same for a `verses_fts` built once from the Bible JSON (fixes B4 — no more full scans).

2. **Ranking = BM25 + field boosts.** `bm25(songs_fts, 10.0, 1.0, 3.0, 2.0)` weights title ≫ lyrics. Add boosts for exact-title, prefix-title, whole-word.

3. **Hindi phonetic layer.** Normalize sibilants (श/ष/स), retroflex/dental (ण/न, ड/ढ), nukta, anusvara/chandrabindu, matra variants → a phonetic key column so "यीशू" ≈ "यीशु" ≈ "ईशु".

4. **Transliteration.** Map common romanised queries (yeeshu, prabhu, aatma, pavitra) → Devanagari before searching, so English-keyboard users find Hindi hymns.

5. **Typo tolerance.** Bounded Levenshtein (≤2) fallback on titles when FTS returns few hits.

6. **Synonym expansion.** Small curated map (प्रभु↔यीशु↔मसीह, आत्मा↔रूह, etc.) — this is the "semantic-lite" bit that makes results feel smart without an ML model.

7. **UX.** 200 ms debounce, match highlighting, "did you mean X", category + first-letter (Hindi alphabet) filters, recent + popular searches, empty/no-result states.

**Ranking pipeline:** FTS candidates → score = `w1·BM25 + w2·fieldBoost + w3·phoneticMatch + w4·prefixBoost − w5·editDistance` → sort → highlight. Weights tunable, covered by unit tests.

**New/changed files:** `data/search/search_index.dart` (index build), `data/search/hindi_phonetic.dart`, `data/search/transliterate.dart`, `data/search/synonyms.dart`, `data/repositories/search_repository.dart` (replaces raw queries in `content_repository`/`bible_repository`), tests in `test/search/`.

---

## 4. Reader / TTS / E-ink (Phase 3 detail)

- **TTS:** `flutter_tts` → Android native engine (offline). Controls: play/pause/stop, sentence-by-sentence highlight, rate slider, pitch, Hindi (`hi-IN`) voice picker with fallback. Handle audio focus (pause on call), and the church-courtesy volume path already present.
- **Reader settings sheet** (shared widget, reused by Songs/Catechism/Bible): font size, line height, letter/word spacing, serif↔sans (fonts already bundled), text alignment, theme (default/sepia/e-ink), brightness lock.
- **E-ink mode:** dedicated `ThemeExtension` → flat `#111` on `#F7F5EF`, zero gradient/shadow/elevation, `pageTransitionsTheme` disabled, replace scroll with **paginated tap-to-turn** view, optional refresh-flash minimization. Persisted via `LocalStorageService`.
- **Fix B9 alignment:** default lyrics to `TextAlign.start` (center is user-optional), verify Devanagari matra rendering with `NotoSerifDevanagari` + proper `height`/`textHeightBehavior`, test long conjuncts.

**New/changed files:** `services/tts_service.dart`, `shared/widgets/reader_settings_sheet.dart`, `shared/widgets/paginated_reader.dart`, `core/theme/eink_theme.dart`, edits to the three reader screens.

---

## 5. Enhanced planner (Phase 4 detail)

New feature module `features/planner/`:
- **Reading plans:** presets (1-year chronological, NT-in-90, Gospels-40, Psalms-30) + custom. Daily items, checkoff, progress ring, "resume where you left off". New tables `reading_plans`, `plan_progress`.
- **Prayer planner:** multiple daily prayer times, named intentions, streak, reminder per slot.
- **Habit heatmap:** GitHub-style calendar of prayer/reading days (extends existing `ProgressStats.currentStreak`).
- **Custom reminders UI:** replace hardcoded schedules in `notification_service.dart` with user-configurable times/days; store and reschedule on boot.
- **"Today" hub** on Home: verse + today's reading + next prayer + weather in one card.
- All offline-first, synced through existing `sync_queue`.

---

## 6. Weather + interactive (Phase 5 detail)

- **Weather:** `geolocator` for coarse location → **Open-Meteo** (free, keyless) current + daily. Cache last result; offline shows last-known + manual city entry. Permission-optional (degrade to manual city).
- **Interactive menu (pick 2–4):**
  - Share verse/hymn as a designed **image card**.
  - **Quiz badges/streaks** + leaderboard-lite (local).
  - **Hymn audio playlists** (queue TTS or bundled audio if you have recordings — §9 Q3).
  - **Bible highlights & bookmarks** with colors + notes.
  - **Home-screen widget** (daily verse) via `home_widget`.
  - Quick theme/e-ink **toggle** in app bar.

---

## 7. Non-negotiable production checklist (Phase 6)
Icon/splash · Crashlytics · analytics · offline states · a11y (TalkBack, contrast, 48dp targets) · Firestore rules · privacy policy + Play data-safety · signed AAB · versioning · CI build · core unit tests.

---

## 8. Risks / watch-items
- **Bible JSON in ZIP is heavy** — Phase 2 FTS index removes per-keystroke cost but first-run indexing must be backgrounded with progress UI.
- **Hindi TTS voice quality** varies by device/engine; may need Google TTS engine prompt or bundled audio fallback.
- **First-run index build time** (songs + ~31k verses) — do it async, show progress, cache.
- **Firebase free-tier** — keep static content local (already the design); only user data syncs.
- **Play Store policy** — data-safety + privacy policy required before release.

---

## 9. Decisions (resolved)
1. **Firebase:** project **`sakshivani-lutherans`** provided (project_number 508965701606). Package id **`com.sakshivani.Lutherans`** (from `google-services.json` — `applicationId` MUST match this exactly). `google-services.json` at `D:\Sakshivani launch app\Sakshivani-Gossener-Lutherans\google-services (2).json`. **Gap:** `oauth_client` empty → Google Sign-In needs SHA-1 added in console (done in Phase 1). Verify Auth providers + Firestore enabled (§11 steps 2–4).
2. **Bible search scope:** **Hindi + English** both searchable/ranked.
3. **Audio:** "listen" = **TTS only** (`flutter_tts`), no bundled recordings.
4. **Brand art:** *still needed* — logo/icon PNG (≥512px) for adaptive icon + splash. Fallback: generate a simple terracotta `#93452B` mark from app name if none provided.
5. **Play Store:** **in scope** — Phase 6 targets signed AAB → Play internal testing. (You'll need a Google Play Developer account, $25 one-time.)
6. **Interactive extras:** none prioritized → Phase 5 = **weather only**, interactive extras deferred/optional. (Revisit later.)

Still open: **Q4 brand art**. Not blocking Phases 1–5; needed for Phase 6 release.

---

## 11. Firebase project setup (you do this; ~10 min)
Do this in parallel; I wire it in Phase 1.
1. Go to console.firebase.google.com → **Add project** → name it (e.g. `sakshi-vani`). Disable Analytics for now (or keep — free). Stay on **Spark (free)** plan.
2. **Authentication → Get started →** enable providers: **Email/Password**, **Google**, **Anonymous**.
3. **Firestore Database → Create database →** Production mode, region closest to India (`asia-south1`).
4. Paste these rules (Firestore → Rules):
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{uid}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == uid;
       }
     }
   }
   ```
5. That's it — **don't** add the Android app manually. I'll run `flutterfire configure` which registers `com.sakshivani.app`, downloads `google-services.json`, and generates real `firebase_options.dart`. I just need you logged into the Firebase CLI on the build machine, or the project id.

---

## 10. Proposed first step
On approval, I start **Phase 1** (make it build on Android) since nothing else can be tested until the app runs on a device. I'll need answers to Q1 (Firebase) and Q4 (icon) but can scaffold `android/` and stub Firebase-off mode immediately without them.
