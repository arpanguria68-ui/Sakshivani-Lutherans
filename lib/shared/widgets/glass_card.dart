import 'package:flutter/material.dart';

/// Editorial card: softly rounded corners, flat tinted surface, hairline
/// border, gentle lift shadow. Ported from the "Sacred Gallery" / dashboard
/// prototype — a subtle background shift on tap is the only extra affordance.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.tone,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Optional background tint override (e.g. secondaryContainer for an
  /// accent card). Defaults to surfaceContainerLow.
  final Color? tone;

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color background = tone ?? colors.surfaceContainerLow;
    final Color border = Color.fromRGBO(
      colors.outlineVariant.red,
      colors.outlineVariant.green,
      colors.outlineVariant.blue,
      0.4,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: colors.primary.withValues(alpha: 0.04),
        splashColor: colors.primary.withValues(alpha: 0.06),
        highlightColor: colors.primary.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: borderRadius,
            border: Border.all(color: border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
