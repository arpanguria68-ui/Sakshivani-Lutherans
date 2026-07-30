# Application Debugging and Audit Plan - Sakshi Vani

This plan outlines a comprehensive audit and debugging strategy for the Sakshi Vani Flutter application. The goal is to identify potential stability issues, performance bottlenecks, and architectural weaknesses across all core features.

## User Review Required

> [!IMPORTANT]
> This audit will involve reading many files across the project. Some proposed fixes might involve changing core repository logic (e.g., Search, Sync, and Zip extraction). Please confirm if you want me to proceed with applying fixes as I find them, or if I should just report them first.

## Audit Scope

The audit will cover the following key areas:

### 1. Core Services & Infrastructure
- **Initialization (Bootstrap)**: Verify error handling during Firebase and Database setup.
- **Authentication**: Audit the "Local Guest" fallback and anonymous user linking.
- **Database (SQFLite)**: Review schema migrations and the dual-database setup (App DB + Songs DB).
- **Sync Service**: Evaluate the reliability of the offline-first sync queue.

### 2. Feature-Specific Logic
- **Bible Reader**:
    - Audit the custom ZIP extraction logic in `BibleRepository`.
    - Review the search performance (linear scan vs. indexed search).
    - Evaluate the TTS integration and lifecycle management.
- **Songs & Catechism**: Check data loading and display performance for large lists.
- **Planner & Journey**: Verify streak logic and heatmap data integrity.
- **Weather Service**: Check location permission handling and API error scenarios.
- **Notifications**: Review scheduling logic and background task reliability.

### 3. Performance & UI/UX
- **Asset Management**: Audit the usage of numerous 3D icons and large assets.
- **State Management**: Ensure Riverpod providers are used efficiently (watching vs. reading).
- **Reader Experience**: Test the "Paper" surface mode and custom themes.

## Proposed Research Steps

### [Component] Infrastructure & Data
- [ ] Deep dive into `BibleRepository`'s custom ZIP parsing.
- [ ] Analyze `AppDatabase` migration logic.
- [ ] Review `SyncService` error retry mechanisms.

### [Component] Features
- [ ] Audit `SearchRepository` for performance issues.
- [ ] Review `WeatherService` for edge cases (no GPS, no internet).
- [ ] Evaluate `TtsService` for engine-specific quirks on Android.

## Verification Plan

### Automated Tests
- Run existing tests: `flutter test`.
- Add unit tests for identified high-risk areas (e.g., Zip extraction, Search).

### Manual Verification
- Test offline mode behavior.
- Verify sync when switching from guest to authenticated user.
- Test Bible reader navigation and TTS on various chapters.
