# Sakshi Vani: Comprehensive Audit & Debugging Report

This report summarizes the findings of a deep-dive audit of the Sakshi Vani codebase.

## 1. Infrastructure & Data Layer

### 1.1 Bible Repository (Custom ZIP Logic)
- **Finding**: `_extractFromZip` manually implements ZIP parsing by signature hunting.
- **Risk**: Brittle if the ZIP contains extra fields or if signatures appear in the data itself.
- **Recommendation**: Switch to a robust package like `archive` or ensure the ZIP is created in a way that avoids these edge cases.

### 1.2 Search Performance & Memory
- **Finding**: Search indexes (~31k verses) are built in-memory on the main thread.
- **Risk**:
    - Building the index can cause significant jank (frames dropped).
    - Memory usage is high (~50-100MB+ for strings and postings lists).
    - `BibleRepository.search` is a slow linear scan (O(N)) used as a fallback.
- **Recommendation**: Move index building to an `Isolate`. Consider using `sqflite` FTS5 or a more memory-efficient data structure for postings.

### 1.3 Sync Service
- **Finding**: Cloud-to-local sync (pull) is missing.
- **Risk**: Favorites/Reflections are not restored when reinstalling or using a second device.
- **Recommendation**: Implement a simple pull-and-merge strategy during bootstrap or account login.

## 2. Platform & Services

### 2.1 Notifications (Permissions)
- **Finding**: Uses `USE_EXACT_ALARM`.
- **Risk**: Potential Google Play Store rejection for non-alarm/calendar apps.
- **Recommendation**: Evaluate if `AndroidScheduleMode.inexactAllowWhileIdle` is sufficient for all reminders.

### 2.2 Weather Service
- **Finding**: No timeout or `getLastKnownPosition` fallback in `fetchByLocation`.
- **Risk**: App may appear "stuck" if GPS lock takes too long indoors.
- **Recommendation**: Add a 5-10s timeout to `getCurrentPosition` and use `getLastKnownPosition` as a fallback.

### 2.3 TTS Service
- **Finding**: Potential race condition in `_scanEngines` if `setPreferredEngine` is called simultaneously.
- **Risk**: `flutter_tts` might get confused or throw exceptions.
- **Recommendation**: Ensure `_initFuture` is awaited before any manual engine changes.

## 3. Auth Logic
- **Finding**: `AuthController._humanizeError` uses string matching on error messages.
- **Risk**: Error strings can change between SDK versions.
- **Recommendation**: Catch `FirebaseAuthException` and use the `.code` property for reliable mapping.

---

## Proposed Debugging & Fixes

I recommend addressing the following in order of priority:

1.  **Isolate-based Search Indexing**: Prevent main-thread jank.
2.  **Weather Fallback**: Improve location reliability.
3.  **Auth Error Handling**: Improve reliability of error messages.
4.  **Sync Pull**: (Future feature) to ensure data persistence.
