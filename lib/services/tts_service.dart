import 'package:flutter_tts/flutter_tts.dart';

/// Info about one installed TTS engine and the languages we care about.
class TtsEngineInfo {
  const TtsEngineInfo({
    required this.id,
    required this.label,
    required this.isDefault,
    required this.supportsHindi,
    required this.supportsEnglish,
    required this.languageCount,
  });

  final String id;
  final String label;
  final bool isDefault;
  final bool supportsHindi;
  final bool supportsEnglish;
  final int languageCount;
}

/// Wrapper over flutter_tts for line-by-line read-aloud.
///
/// Engine-aware: it discovers installed TTS engines, lets the user pick a
/// preferred one, and — crucially — for any content language the chosen engine
/// can't speak (commonly Hindi on OEM engines like Samsung) it falls back to
/// Google TTS automatically, per line.
class TtsService {
  TtsService() {
    _initFuture = _init();
  }

  static const String googleEngine = 'com.google.android.tts';

  final FlutterTts _tts = FlutterTts();
  late final Future<void> _initFuture;

  bool _cancelled = false;
  int _currentLine = 0;
  bool _isSpeaking = false;

  String? _preferredEngine; // null = auto
  String? _defaultEngine;
  String? _activeEngine; // currently set on the plugin
  final Map<String, Set<String>> _engineLangs = <String, Set<String>>{};

  int get currentLine => _currentLine;
  bool get isSpeaking => _isSpeaking;

  Future<void> _init() async {
    await _tts.awaitSpeakCompletion(true);
    await _scanEngines();
  }

  /// Enumerate engines and the languages each supports (one-time, cached).
  Future<void> _scanEngines() async {
    try {
      _defaultEngine = (await _tts.getDefaultEngine) as String?;
    } catch (_) {}
    List<String> engines = <String>[];
    try {
      final dynamic e = await _tts.getEngines;
      if (e is List) engines = e.map((dynamic x) => x.toString()).toList();
    } catch (_) {}

    for (final String engine in engines) {
      try {
        await _tts.setEngine(engine);
        final dynamic langs = await _tts.getLanguages;
        final Set<String> set = <String>{};
        if (langs is List) {
          for (final dynamic l in langs) {
            set.add(l.toString().toLowerCase());
          }
        }
        _engineLangs[engine] = set;
      } catch (_) {
        _engineLangs[engine] = <String>{};
      }
    }
    // Leave the plugin on a sensible engine (preferred > default > google).
    final String? initial = _preferredEngine ?? _defaultEngine ??
        (_engineLangs.containsKey(googleEngine) ? googleEngine : null);
    if (initial != null) {
      await _setEngine(initial);
    }
  }

  Future<void> _setEngine(String engine) async {
    if (_activeEngine == engine) return;
    try {
      await _tts.setEngine(engine);
      _activeEngine = engine;
    } catch (_) {}
  }

  /// Human label for a known engine package.
  static String labelFor(String id) {
    if (id == googleEngine) return 'Google';
    if (id.contains('samsung')) return 'Samsung';
    if (id.contains('pico')) return 'Pico';
    final List<String> parts = id.split('.');
    return parts.isEmpty ? id : parts.last;
  }

  bool _supports(String engine, String locale) {
    final Set<String>? set = _engineLangs[engine];
    if (set == null) return false;
    final String l = locale.toLowerCase();
    if (set.contains(l)) return true;
    final String lang = l.split('-').first;
    return set.any((String s) => s == lang || s.startsWith('$lang-'));
  }

  /// Choose the best engine for [locale]: preferred (if it supports it), else
  /// Google, else any engine that supports it, else null (unsupported anywhere).
  String? _engineFor(String locale) {
    if (_preferredEngine != null && _supports(_preferredEngine!, locale)) {
      return _preferredEngine;
    }
    if (_supports(googleEngine, locale)) return googleEngine;
    if (_defaultEngine != null && _supports(_defaultEngine!, locale)) {
      return _defaultEngine;
    }
    for (final String e in _engineLangs.keys) {
      if (_supports(e, locale)) return e;
    }
    return null;
  }

  /// Pick a TTS locale from the content (Devanagari -> hi-IN, else en-US).
  static String localeFor(String text) {
    for (final int r in text.runes) {
      if (r >= 0x0900 && r <= 0x097F) return 'hi-IN';
    }
    return 'en-US';
  }

  // ─── Engine info + preference (for settings UI) ────────────────────────────

  Future<List<TtsEngineInfo>> availableEngines() async {
    await _initFuture;
    return _engineLangs.entries.map((MapEntry<String, Set<String>> e) {
      return TtsEngineInfo(
        id: e.key,
        label: labelFor(e.key),
        isDefault: e.key == _defaultEngine,
        supportsHindi: _supports(e.key, 'hi-IN'),
        supportsEnglish: _supports(e.key, 'en-US'),
        languageCount: e.value.length,
      );
    }).toList()
      ..sort((TtsEngineInfo a, TtsEngineInfo b) => a.label.compareTo(b.label));
  }

  String? get preferredEngine => _preferredEngine;

  Future<void> setPreferredEngine(String? engine) async {
    // _scanEngines() probes every installed engine (calling setEngine on each
    // in turn) and then settles the plugin on a default at the end; letting
    // a manual pick race that would just get overwritten by the scan's tail.
    await _initFuture;
    _preferredEngine = engine;
    if (engine != null) await _setEngine(engine);
  }

  /// True if some installed engine can speak Hindi.
  Future<bool> hindiAvailableAnywhere() async {
    await _initFuture;
    return _engineFor('hi-IN') != null;
  }

  Future<void> _configure(String locale, double rate, double pitch) async {
    final String? engine = _engineFor(locale);
    if (engine != null) await _setEngine(engine);
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    await _tts.setVolume(1.0);
  }

  /// Speak [lines] from [startIndex]. [onHindiUnavailable] fires once, before
  /// speaking, only if the content needs Hindi and no installed engine has it.
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
    if (needsHindi && _engineFor('hi-IN') == null) {
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

  Future<void> pause() async {
    _cancelled = true;
    _isSpeaking = false;
    await _tts.stop();
  }

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
