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
    apiKey: 'AIzaSyDJXfVC9kTHTdg2u6h_E_Aefp0aVeVay0o',
    appId: '1:251389252229:android:26264732346534cfa08fec',
    messagingSenderId: '251389252229',
    projectId: 'sakshivani-60029',
    storageBucket: 'sakshivani-60029.firebasestorage.app',
  );
}
