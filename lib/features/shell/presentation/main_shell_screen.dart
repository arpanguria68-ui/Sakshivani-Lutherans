import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/shell_tabs_provider.dart';
import '../../../shared/widgets/app_backdrop.dart';
import '../../../shared/widgets/editorial.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label, this.route);
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late int _index;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home, 'Home', '/tab/home'),
    _NavItem(Icons.library_music_outlined, Icons.library_music, 'Songs', '/tab/songs'),
    _NavItem(Icons.menu_book_outlined, Icons.menu_book, 'Bible', '/tab/bible'),
    _NavItem(Icons.insights_outlined, Icons.insights, 'Journey', '/tab/journey'),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = ref.watch(shellTabsProvider);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          _index == 0 ? 'साक्षी वाणी' : _items[_index].label,
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
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
      bottomNavigationBar: _ClayNavBar(
        items: _items,
        index: _index,
        onSelect: (int idx) {
          if (idx == _index) return;
          setState(() => _index = idx);
          context.go(_items[idx].route);
        },
      ),
    );
  }
}

/// Floating rounded pill nav — mirrors the dashboard-web prototype's
/// `.sv-nav` bar, with the Songs tab rendered as an emphasized circular hub.
class _ClayNavBar extends StatelessWidget {
  const _ClayNavBar({
    required this.items,
    required this.index,
    required this.onSelect,
  });

  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  static const Color _primary = Color(0xFF93452B);
  static const Color _cream = Color(0xFFFDF7F2);
  static const Color _creamDeep = Color(0xFFF0E2D4);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[_cream, _creamDeep],
            ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: <BoxShadow>[
              BoxShadow(color: _primary.withValues(alpha: 0.20), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List<Widget>.generate(items.length, (int i) {
              final bool selected = i == index;
              final bool emphasized = items[i].label == 'Songs';

              if (emphasized) {
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFFC26040), _primary],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(color: _primary.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(selected ? items[i].activeIcon : items[i].icon, color: Colors.white, size: 20),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? _primary.withValues(alpha: 0.10) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        selected ? items[i].activeIcon : items[i].icon,
                        size: 20,
                        color: selected ? _primary : const Color(0xFF88726C),
                      ),
                      const SizedBox(height: 2),
                      EyebrowLabel(
                        items[i].label,
                        fontSize: 8.5,
                        color: selected ? _primary : const Color(0xFF88726C),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
