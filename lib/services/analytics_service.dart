import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper over [FirebaseAnalytics] for this app's core interaction
/// events. A no-op when Firebase isn't configured (local-only builds, or
/// `firebase_options.dart` still has placeholder values) — mirrors the
/// `firebaseEnabled` guard already used by `AuthRepository`/`SyncService`.
class AnalyticsService {
  AnalyticsService({required bool firebaseEnabled}) : _firebaseEnabled = firebaseEnabled;

  final bool _firebaseEnabled;

  Future<void> _log(String name, [Map<String, Object>? parameters]) async {
    if (!_firebaseEnabled) {
      return;
    }
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
    } catch (_) {
      // Analytics is best-effort; never let a logging failure surface to the user.
    }
  }

  Future<void> logSongOpened({required int songId, required String book}) {
    return _log('song_opened', <String, Object>{'song_id': songId, 'book': book});
  }

  Future<void> logDailyVerseViewed({required String reference}) {
    return _log('daily_verse_viewed', <String, Object>{'reference': reference});
  }

  Future<void> logBibleChapterRead({
    required String language,
    required int bookIndex,
    required int chapterIndex,
  }) {
    return _log('bible_chapter_read', <String, Object>{
      'language': language,
      'book_index': bookIndex,
      'chapter_index': chapterIndex,
    });
  }

  Future<void> logQuizCompleted({required int score, required int total}) {
    return _log('quiz_completed', <String, Object>{'score': score, 'total': total});
  }

  Future<void> logReadingPlanStarted({required String planKey}) {
    return _log('reading_plan_started', <String, Object>{'plan_key': planKey});
  }
}
