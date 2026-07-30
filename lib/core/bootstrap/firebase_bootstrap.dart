import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static bool _enabled = false;

  static bool get isEnabled => _enabled;

  static bool get hasPlaceholderConfig {
    FirebaseOptions options;
    try {
      options = DefaultFirebaseOptions.currentPlatform;
    } on UnsupportedError {
      return true;
    }
    return options.apiKey.contains('REPLACE_') ||
        options.projectId.contains('replace-') ||
        options.appId.contains('replace_me') ||
        options.messagingSenderId == '000000000000';
  }

  static Future<bool> initialize() async {
    FirebaseOptions options;
    try {
      options = DefaultFirebaseOptions.currentPlatform;
    } on UnsupportedError {
      _enabled = false;
      return false;
    }

    if (hasPlaceholderConfig) {
      _enabled = false;
      return false;
    }

    try {
      await Firebase.initializeApp(options: options);
      _enabled = true;
      return true;
    } catch (_) {
      _enabled = false;
      return false;
    }
  }
}
