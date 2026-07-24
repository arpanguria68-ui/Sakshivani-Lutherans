import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF93452B);

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ).copyWith(
      secondary: const Color(0xFF76546A),
      tertiary: const Color(0xFFB25D41),
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

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        AppBackgroundTheme(gradient: backgroundGradient),
      ],
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontFamily: 'NotoSansDevanagari',
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontFamily: 'NotoSansDevanagari',
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontFamily: 'NotoSansDevanagari',
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontFamily: 'NotoSerifDevanagari',
          height: 1.5,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontFamily: 'NotoSerifDevanagari',
          height: 1.45,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _withAlpha(scheme.surface, brightness == Brightness.light ? 0.86 : 0.64),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: _withAlpha(scheme.outlineVariant, 0.45)),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _withAlpha(scheme.surfaceContainerHighest, 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
