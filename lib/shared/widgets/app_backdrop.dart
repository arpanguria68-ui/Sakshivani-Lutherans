import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppBackgroundTheme? extension =
        Theme.of(context).extension<AppBackgroundTheme>();
    final List<Color> gradient = extension?.gradient ??
        <Color>[Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -40,
            left: -20,
            child: _Blob(
              color: Color.fromRGBO(
                Theme.of(context).colorScheme.primary.red,
                Theme.of(context).colorScheme.primary.green,
                Theme.of(context).colorScheme.primary.blue,
                0.09,
              ),
              size: 180,
            ),
          ),
          Positioned(
            right: -50,
            bottom: 120,
            child: _Blob(
              color: Color.fromRGBO(
                Theme.of(context).colorScheme.secondary.red,
                Theme.of(context).colorScheme.secondary.green,
                Theme.of(context).colorScheme.secondary.blue,
                0.10,
              ),
              size: 200,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size),
        ),
      ),
    );
  }
}
