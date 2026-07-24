import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/catechism/presentation/catechism_chapter_screen.dart';
import '../../features/catechism/presentation/catechism_screen.dart';
import '../../features/quiz/presentation/quiz_screen.dart';
import '../../features/search/presentation/global_search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/main_shell_screen.dart';
import '../../features/songs/presentation/song_reader_screen.dart';
import '../providers.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ProviderRef<GoRouter> ref) {
  final AuthState authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final bool authRoute = state.matchedLocation.startsWith('/auth');
      if (authRoute && authState.isAuthenticated) {
        return '/';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => const MainShellScreen(),
      ),
      GoRoute(
        path: '/song/:songId',
        builder: (BuildContext context, GoRouterState state) {
          final String songId = state.pathParameters['songId'] ?? '1';
          return SongReaderScreen(songId: int.tryParse(songId) ?? 1);
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
