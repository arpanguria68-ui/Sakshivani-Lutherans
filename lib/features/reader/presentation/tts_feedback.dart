import 'package:flutter/material.dart';

/// Shown when read-aloud needs Hindi but the device engine has no hi-IN voice.
void warnHindiVoiceMissing(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Hindi voice not installed. Open Settings → General management → '
        'Text-to-speech and install the Hindi voice (Google TTS).',
      ),
      duration: Duration(seconds: 6),
    ),
  );
}
