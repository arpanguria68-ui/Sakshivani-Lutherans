import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/email_code_auth_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/phone_auth_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/catechism/presentation/catechism_chapter_screen.dart';
import '../../features/catechism/presentation/catechism_screen.dart';
import '../../features/bible/presentation/bible_reader_screen.dart';
import '../../features/planner/presentation/planner_screen.dart';
import '../../features/quiz/presentation/quiz_screen.dart';
import '../../features/search/presentation/global_search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/main_shell_screen.dart';
import '../../features/songs/presentation/song_reader_screen.dart';
import '../../services/tts_service.dart';
import '../providers.dart';

/// Stops any read-aloud when the user navigates between full-screen routes
/// (leaving a reader by push or pop). Ignores popups (dialogs / bottom sheets)
/// so opening the reader settings sheet doesn't cut playback.
class _TtsStopObserver extends NavigatorObserver {
  _TtsStopObserver(this._tts);
  final TtsService _tts;

  void _stopFor(Route<dynamic>? route) {
    if (route is PageRoute) _tts.stop();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _stopFor(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _stopFor(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _stopFor(newRoute);
}

/// Bridges Riverpod state changes into GoRouter's `refreshListenable` so the
/// *same* long-lived GoRouter re-runs `redirect` against whatever screen is
/// currently showing. Rebuilding a brand-new GoRouter instance on every auth
/// / onboarding change (the previous approach: `ref.watch(...)` inside the
/// provider body) does NOT reliably force navigation on the already-visible
/// screen — swapping `routerConfig` only changes future redirect behavior,
/// so an in-app "reset onboarding" or similar action would silently fail to
/// navigate even though the underlying state was updated correctly.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (_, __) => notifyListeners());
    ref.listen<bool>(onboardingControllerProvider, (_, __) => notifyListeners());
  }
}

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ProviderRef<GoRouter> ref) {
  final _RouterRefreshNotifier refresh = _RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    observers: <NavigatorObserver>[_TtsStopObserver(ref.read(ttsServiceProvider))],
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState authState = ref.read(authControllerProvider);
      final bool onboarded = ref.read(onboardingControllerProvider);

      final bool onOnboarding = state.matchedLocation == '/onboarding';
      if (!onboarded && !onOnboarding) {
        return '/onboarding';
      }
      if (onboarded && onOnboarding) {
        return '/';
      }

      final bool authRoute = state.matchedLocation.startsWith('/auth');
      if (authRoute && authState.isAuthenticated) {
        return '/';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => const MainShellScreen(),
      ),
      GoRoute(
        path: '/song/:book/:songId',
        builder: (BuildContext context, GoRouterState state) {
          final String book = state.pathParameters['book'] ?? 'sakshivani';
          final String songId = state.pathParameters['songId'] ?? '1';
          return SongReaderScreen(book: book, songId: int.tryParse(songId) ?? 1);
        },
      ),
      GoRoute(
        path: '/catechism',
        builder: (BuildContext context, GoRouterState state) => const CatechismScreen(),
      ),
      GoRoute(
        path: '/catechism/:chapterId',
        builder: (BuildContext context, GoRouterState state) {
          final String chapterId = state.pathParameters['chapterId'] ?? '';
          return CatechismChapterScreen(chapterId: chapterId);
        },
      ),
      GoRoute(
        path: '/quiz',
        builder: (BuildContext context, GoRouterState state) => const QuizScreen(),
      ),
      GoRoute(
        path: '/planner',
        builder: (BuildContext context, GoRouterState state) => const PlannerScreen(),
      ),
      GoRoute(
        path: '/bible/read/:lang/:book/:chapter',
        builder: (BuildContext context, GoRouterState state) {
          return BibleReaderScreen(
            language: state.pathParameters['lang'] ?? 'hi',
            bookIndex: int.tryParse(state.pathParameters['book'] ?? '0') ?? 0,
            chapterIndex: int.tryParse(state.pathParameters['chapter'] ?? '0') ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (BuildContext context, GoRouterState state) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (BuildContext context, GoRouterState state) => const AuthScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'forgot',
            builder: (BuildContext context, GoRouterState state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: 'phone',
            builder: (BuildContext context, GoRouterState state) => const PhoneAuthScreen(),
          ),
          GoRoute(
            path: 'email-code',
            builder: (BuildContext context, GoRouterState state) => const EmailCodeAuthScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/tab/home',
        builder: (BuildContext context, GoRouterState state) => const MainShellScreen(initialIndex: 0),
      ),
      GoRoute(
        path: '/tab/songs',
        builder: (BuildContext context, GoRouterState state) => const MainShellScreen(initialIndex: 1),
      ),
      GoRoute(
        path: '/tab/bible',
        builder: (BuildContext context, GoRouterState state) => const MainShellScreen(initialIndex: 2),
      ),
      GoRoute(
        path: '/tab/journey',
        builder: (BuildContext context, GoRouterState state) => const MainShellScreen(initialIndex: 3),
      ),
    ],
  );
});
