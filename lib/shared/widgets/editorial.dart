import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Clay palette for [BentoCard] — matches the dashboard-web prototype's
/// `.bento-card` / `.bento-card.accent` gradients exactly.
class _ClayColors {
  static const Color cream = Color(0xFFFDF7F2);
  static const Color creamDeep = Color(0xFFEEDDD0);
  static const Color accentLt = Color(0xFFFFF0EA);
  static const Color accentDp = Color(0xFFF5D5C4);
  static const Color primary = Color(0xFF93452B);

  /// Fixed dark ink for text painted on the clay card — the card is always
  /// light regardless of app theme brightness, so text must not follow it.
  static const Color ink = Color(0xFF2A1810);
}

/// Small uppercase, letter-spaced label — the "eyebrow" text used throughout
/// the editorial design (e.g. "THE DAILY REMEMBRANCE", "SPIRITUALITY PROGRESS").
class EyebrowLabel extends StatelessWidget {
  const EyebrowLabel(
    this.text, {
    super.key,
    this.color,
    this.fontSize = 10,
  });

  final String text;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: AppTheme.labelFont,
        fontFamilyFallback: const <String>['NotoSansDevanagari'],
        fontSize: fontSize,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w600,
        color: color ?? colors.secondary,
      ),
    );
  }
}

/// A hairline (1px) progress indicator with an eyebrow label + percentage row
/// above it — replaces the chunky Material [LinearProgressIndicator] for the
/// editorial look.
class ThinProgressLine extends StatelessWidget {
  const ThinProgressLine({
    super.key,
    required this.label,
    required this.value,
    this.valueLabel,
  });

  final String label;
  final double value; // 0..1
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double clamped = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            EyebrowLabel(label),
            EyebrowLabel(valueLabel ?? '${(clamped * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 1,
          child: Stack(
            children: <Widget>[
              Container(color: colors.outlineVariant.withValues(alpha: 0.3)),
              FractionallySizedBox(
                widthFactor: clamped,
                child: Container(color: colors.secondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The hero "verse plate": a tinted banner with an eyebrow label, a large
/// italic serif quote, and a thin center divider — the editorial stand-in for
/// a full-bleed photograph (kept illustrative/gradient since the app ships
/// no stock photography).
class VersePlate extends StatelessWidget {
  const VersePlate({
    super.key,
    required this.eyebrow,
    required this.quote,
    this.onTap,
    this.accentSrc,
    this.backgroundSrc,
  });

  final String eyebrow;
  final String quote;
  final VoidCallback? onTap;

  /// Optional clay/3D icon watermark in the top-right corner.
  final String? accentSrc;

  /// Optional photo background (e.g. `assets/backgrounds/sunrise.png`).
  /// Falls back to the plain tinted gradient when omitted.
  final String? backgroundSrc;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 21 / 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: backgroundSrc != null
                  ? DecorationImage(image: AssetImage(backgroundSrc!), fit: BoxFit.cover)
                  : null,
              gradient: backgroundSrc != null
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        colors.primary.withValues(alpha: 0.16),
                        colors.tertiary.withValues(alpha: 0.10),
                        colors.surfaceContainerLow,
                      ],
                    ),
            ),
            child: Stack(
              children: <Widget>[
                if (backgroundSrc != null)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            Colors.black.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0.22),
                            Colors.black.withValues(alpha: 0.50),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (accentSrc != null)
                  Positioned(
                    top: 10,
                    right: 14,
                    child: Opacity(
                      opacity: 0.5,
                      child: Image.asset(accentSrc!, width: 40, height: 40, fit: BoxFit.contain),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      EyebrowLabel(
                        eyebrow,
                        color: backgroundSrc != null
                            ? Colors.white.withValues(alpha: 0.75)
                            : colors.onSurface.withValues(alpha: 0.55),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '"$quote"',
                        textAlign: TextAlign.center,
                        style: text.headlineSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                          color: backgroundSrc != null ? Colors.white : colors.onSurface,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: 1,
                        height: 28,
                        color: backgroundSrc != null
                            ? Colors.white.withValues(alpha: 0.5)
                            : colors.primary.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A bento-grid quick-action card: icon, italic title, short description, and
/// a footer row (status label + arrow) — mirrors the "Morning Prayer /
/// Sacred Study / The Sanctuary" cards in the reference design.
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    this.icon,
    this.claySrc,
    required this.title,
    required this.description,
    required this.footerLabel,
    required this.actionLabel,
    required this.onTap,
    this.accent = false,
    this.iconColor,
  }) : assert(icon != null || claySrc != null, 'Provide icon or claySrc');

  /// Material glyph, used when [claySrc] is not provided.
  final IconData? icon;

  /// Path to a bundled clay/3D icon asset — takes priority over [icon] when set.
  final String? claySrc;

  final String title;
  final String description;
  final String footerLabel;
  final String actionLabel;
  final VoidCallback onTap;

  /// Peach/rose clay tint instead of the plain cream card — mirrors the
  /// prototype's alternating `.bento-card.accent` styling.
  final bool accent;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color tint = iconColor ?? _ClayColors.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: accent
                  ? const <Color>[_ClayColors.accentLt, _ClayColors.accentDp]
                  : const <Color>[_ClayColors.cream, _ClayColors.creamDeep],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: <BoxShadow>[
              BoxShadow(color: _ClayColors.primary.withValues(alpha: 0.14), blurRadius: 14, offset: const Offset(5, 6)),
              BoxShadow(color: Colors.white.withValues(alpha: 0.75), blurRadius: 8, offset: const Offset(-3, -3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: claySrc != null
                      ? Image.asset(claySrc!, fit: BoxFit.contain)
                      : Icon(icon, color: tint, size: 22),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: text.titleLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  // Card surface is always the light cream/peach clay tint —
                  // pin ink colors instead of inheriting the app theme, or
                  // dark mode's near-white default text goes invisible here.
                  color: _ClayColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: text.bodySmall?.copyWith(
                  color: _ClayColors.ink.withValues(alpha: 0.72),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(child: EyebrowLabel(footerLabel, color: _ClayColors.primary.withValues(alpha: 0.85))),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '$actionLabel →',
                      style: TextStyle(
                        fontFamily: AppTheme.labelFont,
                        fontFamilyFallback: const <String>['NotoSansDevanagari'],
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        color: tint,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
