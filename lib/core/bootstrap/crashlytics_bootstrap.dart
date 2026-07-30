import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Routes uncaught Flutter framework errors and other async errors to
/// Crashlytics once Firebase is confirmed enabled. Call after
/// `FirebaseBootstrap.initialize()` succeeds; a no-op build (Firebase
/// disabled/unconfigured) never calls this, so there is nothing to guard
/// here beyond the SDK's own behavior.
class CrashlyticsBootstrap {
  const CrashlyticsBootstrap._();

  static void wireErrorReporting() {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Logs a caught, non-fatal error (e.g. a sync retry or init failure) so
  /// it's visible in Crashlytics without crashing the app.
  static Future<void> recordNonFatal(Object error, StackTrace stack, {String? reason}) {
    return FirebaseCrashlytics.instance.recordError(error, stack, reason: reason, fatal: false);
  }
}
