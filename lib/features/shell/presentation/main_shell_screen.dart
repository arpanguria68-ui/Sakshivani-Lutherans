import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/shell_tabs_provider.dart';
import '../../../shared/widgets/app_backdrop.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late int _index;

  static const List<String> _tabTitles = <String>[
    'Home',
    'Songs',
    'Bible',
    'My Journey',
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = ref.watch(shellTabsProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color navSurface = Color.fromRGBO(
      colors.surface.red,
      colors.surface.green,
      colors.surface.blue,
      0.88,
    );
    final Color navBorder = Color.fromRGBO(
      colors.outlineVariant.red,
      colors.outlineVariant.green,
      colors.outlineVariant.blue,
      0.5,
    );

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_tabTitles[_index]),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: AppBackdrop(child: tabs[_index]),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: navSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: navBorder),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            height: 72,
            backgroundColor: Colors.transparent,
            indicatorColor: colors.primaryContainer,
            onDestinationSelected: (int idx) {
              if (idx == _index) {
                return;
              }
              setState(() {
                _index = idx;
              });
              switch (idx) {
                case 0:
                  context.go('/tab/home');
                  break;
                case 1:
                  context.go('/tab/songs');
                  break;
                case 2:
                  context.go('/tab/bible');
                  break;
                case 3:
                  context.go('/tab/journey');
                  break;
              }
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music), label: 'Songs'),
              NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Bible'),
              NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Journey'),
            ],
          ),
        ),
      ),
    );
  }
}
