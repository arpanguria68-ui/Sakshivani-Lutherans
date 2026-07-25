import 'dart:convert';

import 'package:flutter/material.dart';

enum ReaderFontFamily { sans, serif }

enum ReaderAlign { start, center, justify }

/// Reading surface theme. `system` follows the app's light/dark; `sepia` and
/// `eink` are paper-like reading modes (eink = flat grayscale, no motion).
enum ReaderTheme { system, sepia, eink }

@immutable
class ReaderSettings {
  const ReaderSettings({
    this.fontSize = 20,
    this.lineHeight = 1.65,
    this.letterSpacing = 0,
    this.wordSpacing = 0,
    this.font = ReaderFontFamily.serif,
    this.align = ReaderAlign.start,
    this.theme = ReaderTheme.system,
    this.paginated = false,
    this.paperTexture = true,
    this.pageTurnSound = true,
    this.ttsRate = 0.48,
    this.ttsPitch = 1.0,
  });

  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
  final double wordSpacing;
  final ReaderFontFamily font;
  final ReaderAlign align;
  final ReaderTheme theme;
  final bool paginated;
  final bool paperTexture;
  final bool pageTurnSound;
  final double ttsRate;
  final double ttsPitch;

  static const double minFontSize = 14;
  static const double maxFontSize = 40;

  String get fontFamily =>
      font == ReaderFontFamily.serif ? 'NotoSerifDevanagari' : 'NotoSansDevanagari';

  TextAlign get textAlign => switch (align) {
        ReaderAlign.start => TextAlign.start,
        ReaderAlign.center => TextAlign.center,
        ReaderAlign.justify => TextAlign.justify,
      };

  /// True when a paper-like reading surface should override app theming.
  bool get isPaperSurface => theme == ReaderTheme.sepia || theme == ReaderTheme.eink;

  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    double? letterSpacing,
    double? wordSpacing,
    ReaderFontFamily? font,
    ReaderAlign? align,
    ReaderTheme? theme,
    bool? paginated,
    bool? paperTexture,
    bool? pageTurnSound,
    double? ttsRate,
    double? ttsPitch,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      font: font ?? this.font,
      align: align ?? this.align,
      theme: theme ?? this.theme,
      paginated: paginated ?? this.paginated,
      paperTexture: paperTexture ?? this.paperTexture,
      pageTurnSound: pageTurnSound ?? this.pageTurnSound,
      ttsRate: ttsRate ?? this.ttsRate,
      ttsPitch: ttsPitch ?? this.ttsPitch,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'fontSize': fontSize,
        'lineHeight': lineHeight,
        'letterSpacing': letterSpacing,
        'wordSpacing': wordSpacing,
        'font': font.name,
        'align': align.name,
        'theme': theme.name,
        'paginated': paginated,
        'paperTexture': paperTexture,
        'pageTurnSound': pageTurnSound,
        'ttsRate': ttsRate,
        'ttsPitch': ttsPitch,
      };

  factory ReaderSettings.fromMap(Map<String, dynamic> m) {
    T byName<T extends Enum>(List<T> values, Object? name, T fallback) {
      return values.firstWhere((T v) => v.name == name, orElse: () => fallback);
    }

    return ReaderSettings(
      fontSize: (m['fontSize'] as num?)?.toDouble() ?? 20,
      lineHeight: (m['lineHeight'] as num?)?.toDouble() ?? 1.65,
      letterSpacing: (m['letterSpacing'] as num?)?.toDouble() ?? 0,
      wordSpacing: (m['wordSpacing'] as num?)?.toDouble() ?? 0,
      font: byName(ReaderFontFamily.values, m['font'], ReaderFontFamily.serif),
      align: byName(ReaderAlign.values, m['align'], ReaderAlign.start),
      theme: byName(ReaderTheme.values, m['theme'], ReaderTheme.system),
      paginated: m['paginated'] as bool? ?? false,
      paperTexture: m['paperTexture'] as bool? ?? true,
      pageTurnSound: m['pageTurnSound'] as bool? ?? true,
      ttsRate: (m['ttsRate'] as num?)?.toDouble() ?? 0.48,
      ttsPitch: (m['ttsPitch'] as num?)?.toDouble() ?? 1.0,
    );
  }

  String encode() => jsonEncode(toMap());

  factory ReaderSettings.decode(String? json) {
    if (json == null || json.isEmpty) return const ReaderSettings();
    try {
      return ReaderSettings.fromMap(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return const ReaderSettings();
    }
  }
}

/// Resolved colors for a reading surface given the current settings + brightness.
class ReaderPalette {
  const ReaderPalette({
    required this.background,
    required this.text,
    required this.subtle,
    required this.highlight,
    required this.flat,
  });

  final Color background;
  final Color text;
  final Color subtle;
  final Color highlight; // active TTS line background
  final bool flat; // true = suppress gradients/shadows/animation (e-ink)

  static ReaderPalette resolve(ReaderSettings s, Brightness brightness) {
    switch (s.theme) {
      case ReaderTheme.sepia:
        return const ReaderPalette(
          background: Color(0xFFF3E9D5),
          text: Color(0xFF3A2F1B),
          subtle: Color(0xFF7A6A4A),
          highlight: Color(0xFFE4D2A8),
          flat: false,
        );
      case ReaderTheme.eink:
        return const ReaderPalette(
          background: Color(0xFFF7F5EF),
          text: Color(0xFF111111),
          subtle: Color(0xFF555555),
          highlight: Color(0xFFDDDDDD),
          flat: true,
        );
      case ReaderTheme.system:
        final bool dark = brightness == Brightness.dark;
        return ReaderPalette(
          background: dark ? const Color(0xFF15100E) : const Color(0xFFFCF9F4),
          text: dark ? const Color(0xFFECE3DA) : const Color(0xFF241A15),
          subtle: dark ? const Color(0xFFB6A99E) : const Color(0xFF6D5D52),
          highlight: dark ? const Color(0xFF3A2A22) : const Color(0xFFF0E4D6),
          flat: false,
        );
    }
  }
}
