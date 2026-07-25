import 'package:flutter/material.dart';

/// Editorial card: sharp corners, flat tinted surface, hairline border.
/// Ported from the premium "Sacred Gallery" design — no blur, no heavy
/// shadow; a subtle background shift on tap is the only affordance.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.tone,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Optional background tint override (e.g. secondaryContainer for an
  /// accent card). Defaults to surfaceContainerLow.
  final Color? tone;

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
      child: InkWell(
        onTap: onTap,
        hoverColor: colors.primary.withValues(alpha: 0.04),
        splashColor: colors.primary.withValues(alpha: 0.06),
        highlightColor: colors.primary.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border),
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
