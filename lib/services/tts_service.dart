import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper over flutter_tts for reading hymns / verses / catechism aloud,
/// line by line, with per-line callbacks so the UI can highlight the active
/// line. Uses the device's offline TTS engine (no network).
class TtsService {
  TtsService() {
    _tts.awaitSpeakCompletion(true);
  }

  final FlutterTts _tts = FlutterTts();
  bool _cancelled = false;
  int _currentLine = 0;
  bool _isSpeaking = false;

  int get currentLine => _currentLine;
  bool get isSpeaking => _isSpeaking;

  /// Pick a TTS locale from the content (Devanagari -> hi-IN, else en-US).
  static String localeFor(String text) {
    for (final int r in text.runes) {
      if (r >= 0x0900 && r <= 0x097F) return 'hi-IN';
    }
    return 'en-US';
  }

  Future<void> _configure(String locale, double rate, double pitch) async {
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    await _tts.setVolume(1.0);
  }

  /// Speak [lines] starting at [startIndex]. Awaits until finished, cancelled,
  /// or paused. [onLine] fires as each line begins; [onDone] when all lines are
  /// spoken (not on pause/stop).
  Future<void> speakLines(
    List<String> lines, {
    int startIndex = 0,
    required double rate,
    required double pitch,
    required void Function(int index) onLine,
    required void Function() onDone,
  }) async {
    if (lines.isEmpty) return;
    _cancelled = false;
    _isSpeaking = true;
    for (int i = startIndex; i < lines.length; i++) {
      if (_cancelled) break;
      final String line = lines[i].trim();
      _currentLine = i;
      onLine(i);
      if (line.isEmpty) continue;
      await _configure(localeFor(line), rate, pitch);
      await _tts.speak(line);
    }
    _isSpeaking = false;
    if (!_cancelled) onDone();
  }

  /// Pause: stops the engine but remembers the current line for resume().
  Future<void> pause() async {
    _cancelled = true;
    _isSpeaking = false;
    await _tts.stop();
  }

  /// Stop and reset to the beginning.
  Future<void> stop() async {
    _cancelled = true;
    _isSpeaking = false;
    _currentLine = 0;
    await _tts.stop();
  }

  Future<void> dispose() async {
    _cancelled = true;
    await _tts.stop();
  }
}
