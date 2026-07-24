import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color background = Color.fromRGBO(
      colors.surface.red,
      colors.surface.green,
      colors.surface.blue,
      Theme.of(context).brightness == Brightness.light ? 0.86 : 0.58,
    );
    final Color border = Color.fromRGBO(
      colors.outlineVariant.red,
      colors.outlineVariant.green,
      colors.outlineVariant.blue,
      0.45,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
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
