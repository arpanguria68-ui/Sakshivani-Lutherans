import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Flat editorial background — a single warm surface tone, no blur/blobs.
/// Kept as a wrapper (rather than removed) so screens can still opt into the
/// [AppBackgroundTheme] tone without every call site changing.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppBackgroundTheme? extension =
        Theme.of(context).extension<AppBackgroundTheme>();
    final Color background =
        extension?.gradient.first ?? Theme.of(context).colorScheme.surface;

    return ColoredBox(color: background, child: child);
  }
}
