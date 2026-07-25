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
    final ColorScheme colors = Theme.of(context).colorScheme;

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
      bottomNavigationBar: _EditorialNavBar(
        items: _items,
        index: _index,
        onSelect: (int idx) {
          if (idx == _index) return;
          setState(() => _index = idx);
          context.go(_items[idx].route);
        },
        surfaceColor: colors.surface,
        borderColor: colors.outlineVariant.withValues(alpha: 0.35),
      ),
    );
  }
}

class _EditorialNavBar extends StatelessWidget {
  const _EditorialNavBar({
    required this.items,
    required this.index,
    required this.onSelect,
    required this.surfaceColor,
    required this.borderColor,
  });

  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onSelect;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaceColor.withValues(alpha: 0.92),
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List<Widget>.generate(items.length, (int i) {
            final bool selected = i == index;
            final ColorScheme colors = Theme.of(context).colorScheme;
            return Expanded(
              child: InkWell(
                onTap: () => onSelect(i),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? colors.primary.withValues(alpha: 0.08) : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        selected ? items[i].activeIcon : items[i].icon,
                        size: 22,
                        color: selected ? colors.primary : colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      EyebrowLabel(
                        items[i].label,
                        fontSize: 9,
                        color: selected ? colors.primary : colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
