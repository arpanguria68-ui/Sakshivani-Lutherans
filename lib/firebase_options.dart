import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Firebase options are configured for Android only in this project.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAukQjjZSelinaRkuHO_5teNSDGbojKQ3A',
    appId: '1:508965701606:android:9f56a2d4a6c8c5c421f827',
    messagingSenderId: '508965701606',
    projectId: 'sakshivani-lutherans',
    storageBucket: 'sakshivani-lutherans.firebasestorage.app',
  );
}
