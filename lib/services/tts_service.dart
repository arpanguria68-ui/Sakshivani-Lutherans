import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper over flutter_tts for reading hymns / verses / catechism aloud,
/// line by line, with per-line callbacks so the UI can highlight the active
/// line. Uses the device's offline TTS engine (no network).
///
/// Hindi note: many OEM TTS engines (e.g. Samsung) omit Hindi. We prefer the
/// Google TTS engine when present, and report when hi-IN isn't installed so the
/// UI can guide the user to install the voice.
class TtsService {
  TtsService() {
    _initFuture = _init();
  }

  final FlutterTts _tts = FlutterTts();
  late final Future<void> _initFuture;
  bool _cancelled = false;
  int _currentLine = 0;
  bool _isSpeaking = false;

  int get currentLine => _currentLine;
  bool get isSpeaking => _isSpeaking;

  Future<void> _init() async {
    await _tts.awaitSpeakCompletion(true);
    // Prefer the Google engine, which ships Hindi, when it's installed.
    try {
      final dynamic engines = await _tts.getEngines;
      if (engines is List && engines.contains('com.google.android.tts')) {
        await _tts.setEngine('com.google.android.tts');
      }
    } catch (_) {
      // engine selection is best-effort
    }
  }

  /// Pick a TTS locale from the content (Devanagari -> hi-IN, else en-US).
  static String localeFor(String text) {
    for (final int r in text.runes) {
      if (r >= 0x0900 && r <= 0x097F) return 'hi-IN';
    }
    return 'en-US';
  }

  /// Whether [locale] (e.g. 'hi-IN') is available on the current engine.
  Future<bool> isLanguageAvailable(String locale) async {
    try {
      final dynamic r = await _tts.isLanguageAvailable(locale);
      return r == true || r == 1;
    } catch (_) {
      return false;
    }
  }

  Future<void> _configure(String locale, double rate, double pitch) async {
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    await _tts.setVolume(1.0);
  }

  /// Speak [lines] starting at [startIndex]. Awaits until finished, cancelled,
  /// or paused. [onLine] fires as each line begins; [onDone] when all lines are
  /// spoken (not on pause/stop). [onHindiUnavailable] fires once, before
  /// speaking, if the content needs Hindi but hi-IN isn't installed.
  Future<void> speakLines(
    List<String> lines, {
    int startIndex = 0,
    required double rate,
    required double pitch,
    required void Function(int index) onLine,
    required void Function() onDone,
    void Function()? onHindiUnavailable,
  }) async {
    if (lines.isEmpty) return;
    await _initFuture;

    final bool needsHindi = lines.any((String l) => localeFor(l) == 'hi-IN');
    if (needsHindi && !await isLanguageAvailable('hi-IN')) {
      onHindiUnavailable?.call();
    }

    _cancelled = false;
    _isSpeaking = true;
    for (int i = startIndex; i < lines.length; i++) {
      if (_cancelled) break;
      final String line = lines[i].trim();
      _currentLine = i;
      onLine(i);
      if (line.isEmpty) continue;
      await _configure(localeFor(line), rate, pitch);
      if (_cancelled) break;
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
    if (!_isSpeaking && _currentLine == 0) {
      // Nothing playing; still ensure the engine is quiet.
      await _tts.stop();
      return;
    }
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
