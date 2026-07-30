import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sakshi_vani/features/shell/presentation/main_shell_screen.dart';
import 'package:sakshi_vani/features/shell/providers/shell_tabs_provider.dart';

/// Builds the shell behind a real [GoRouter] (rather than just pumping
/// [MainShellScreen] directly) because tab taps call `context.go(...)`,
/// which needs a router ancestor to resolve. Tab bodies are swapped for
/// plain, keyed placeholders via [shellTabsProvider] so the test exercises
/// only the shell's own navigation/index logic, not Home/Songs/Bible/Journey
/// and everything they in turn depend on.
Widget _buildApp() {
  final GoRouter router = GoRouter(
    initialLocation: '/tab/home',
    routes: <RouteBase>[
      GoRoute(path: '/tab/home', builder: (_, __) => const MainShellScreen(initialIndex: 0)),
      GoRoute(path: '/tab/songs', builder: (_, __) => const MainShellScreen(initialIndex: 1)),
      GoRoute(path: '/tab/bible', builder: (_, __) => const MainShellScreen(initialIndex: 2)),
      GoRoute(path: '/tab/journey', builder: (_, __) => const MainShellScreen(initialIndex: 3)),
      GoRoute(path: '/search', builder: (_, __) => const SizedBox.shrink()),
      GoRoute(path: '/settings', builder: (_, __) => const SizedBox.shrink()),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      shellTabsProvider.overrideWithValue(const <Widget>[
        Text('HomeContent'),
        Text('SongsContent'),
        Text('BibleContent'),
        Text('JourneyContent'),
      ]),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('starts on Home and shows the Hindi app title', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('साक्षी वाणी'), findsOneWidget);
    expect(find.text('HomeContent'), findsOneWidget);
  });

  testWidgets('tapping the Songs icon switches tab body and app bar title', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.library_music_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Songs'), findsOneWidget);
    expect(find.text('SongsContent'), findsOneWidget);
    expect(find.text('HomeContent'), findsNothing);
  });

  testWidgets('tapping the Bible icon switches tab body and app bar title', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Bible'), findsOneWidget);
    expect(find.text('BibleContent'), findsOneWidget);
  });

  testWidgets('tapping the Journey icon switches tab body and app bar title', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.insights_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('JourneyContent'), findsOneWidget);
  });

  testWidgets('tapping the currently-active tab does not rebuild/navigate', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();

    expect(find.text('HomeContent'), findsOneWidget);
  });
}
