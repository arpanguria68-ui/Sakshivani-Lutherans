import 'package:flutter/material.dart';

/// "The Sacred Gallery" editorial theme — ported from the dashboard-web
/// prototype: warm cream/clay surfaces, italic serif headlines, softly
/// rounded cards and pill controls, uppercase tracked labels, and thin
/// hairline dividers instead of chunky Material defaults.
class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF93452B);

  /// Editorial headline face (English/Latin); Devanagari falls back to the
  /// bundled Noto faces automatically via [_devanagariHeadingFallback].
  static const String headlineFont = 'Newsreader';
  static const String labelFont = 'Inter';

  static const List<String> _devanagariHeadingFallback = <String>['NotoSerifDevanagari'];
  static const List<String> _devanagariLabelFallback = <String>['NotoSansDevanagari'];

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ).copyWith(
      secondary: const Color(0xFF76546A),
      tertiary: const Color(0xFFB25D41),
      surface: const Color(0xFFFCF9F4),
    );

    return _baseTheme(
      brightness: Brightness.light,
      scheme: scheme,
      backgroundGradient: const [Color(0xFFFCF9F4), Color(0xFFF5EFE7)],
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: const Color(0xFFE5BAD4),
      tertiary: const Color(0xFFD6C3B3),
    );

    return _baseTheme(
      brightness: Brightness.dark,
      scheme: scheme,
      backgroundGradient: const [Color(0xFF1A1210), Color(0xFF2A1A15)],
    );
  }

  static ThemeData _baseTheme({
    required Brightness brightness,
    required ColorScheme scheme,
    required List<Color> backgroundGradient,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'NotoSansDevanagari',
    );

    TextStyle heading(TextStyle? s) => (s ?? const TextStyle()).copyWith(
          fontFamily: headlineFont,
          fontFamilyFallback: _devanagariHeadingFallback,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        );

    TextStyle label(TextStyle? s) => (s ?? const TextStyle()).copyWith(
          fontFamily: labelFont,
          fontFamilyFallback: _devanagariLabelFallback,
          letterSpacing: 0.6,
        );

    const BorderRadius card = BorderRadius.all(Radius.circular(22));
    const BorderRadius pill = BorderRadius.all(Radius.circular(100));
    const BorderRadius field = BorderRadius.all(Radius.circular(14));
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: field,
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        AppBackgroundTheme(gradient: backgroundGradient),
      ],
      textTheme: base.textTheme.copyWith(
        displayLarge: heading(base.textTheme.displayLarge),
        displayMedium: heading(base.textTheme.displayMedium),
        displaySmall: heading(base.textTheme.displaySmall),
        headlineLarge: heading(base.textTheme.headlineLarge),
        headlineMedium: heading(base.textTheme.headlineMedium),
        headlineSmall: heading(base.textTheme.headlineSmall),
        titleLarge: heading(base.textTheme.titleLarge)
            .copyWith(fontWeight: FontWeight.w600),
        titleMedium: heading(base.textTheme.titleMedium)
            .copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1),
        titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontFamily: 'NotoSerifDevanagari',
          height: 1.5,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontFamily: 'NotoSerifDevanagari',
          height: 1.45,
        ),
        labelLarge: label(base.textTheme.labelLarge),
        labelMedium: label(base.textTheme.labelMedium),
        labelSmall: label(base.textTheme.labelSmall).copyWith(letterSpacing: 1.1),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _withAlpha(scheme.surfaceContainerLow, 1),
        shape: RoundedRectangleBorder(
          borderRadius: card,
          side: BorderSide(color: _withAlpha(scheme.outlineVariant, 0.4)),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: heading(base.textTheme.headlineSmall).copyWith(
          fontStyle: FontStyle.italic,
          color: scheme.primary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorShape: const RoundedRectangleBorder(borderRadius: pill),
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          label(base.textTheme.labelSmall).copyWith(fontSize: 10, letterSpacing: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: pill),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: pill),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: pill),
          side: BorderSide(color: scheme.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: pill),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: pill,
          side: BorderSide(color: _withAlpha(scheme.outlineVariant, 0.5)),
        ),
        side: BorderSide(color: _withAlpha(scheme.outlineVariant, 0.5)),
        backgroundColor: scheme.surfaceContainerLow,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: pill)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: field),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: _withAlpha(scheme.outlineVariant, 0.35),
        thickness: 1,
        space: 1,
      ),
    );
  }
}

Color _withAlpha(Color color, double opacity) {
  return Color.fromARGB(
    (opacity * 255).round(),
    color.red,
    color.green,
    color.blue,
  );
}

class AppBackgroundTheme extends ThemeExtension<AppBackgroundTheme> {
  const AppBackgroundTheme({required this.gradient});

  final List<Color> gradient;

  @override
  AppBackgroundTheme copyWith({List<Color>? gradient}) {
    return AppBackgroundTheme(gradient: gradient ?? this.gradient);
  }

  @override
  AppBackgroundTheme lerp(ThemeExtension<AppBackgroundTheme>? other, double t) {
    if (other is! AppBackgroundTheme) {
      return this;
    }

    final List<Color> lerped = <Color>[];
    final int len = gradient.length < other.gradient.length ? gradient.length : other.gradient.length;
    for (int i = 0; i < len; i++) {
      lerped.add(Color.lerp(gradient[i], other.gradient[i], t) ?? gradient[i]);
    }
    return AppBackgroundTheme(gradient: lerped);
  }
}
