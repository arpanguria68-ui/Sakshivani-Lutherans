import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/local/local_storage_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/bible_repository.dart';
import '../data/repositories/content_repository.dart';
import '../data/repositories/favorites_repository.dart';
import '../data/repositories/planner_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/reflection_repository.dart';
import '../data/repositories/sync_queue_repository.dart';
import '../data/search/search_repository.dart';
import '../features/auth/controller/auth_controller.dart';
import '../features/auth/domain/auth_state.dart';
import '../services/church_courtesy_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../services/tts_service.dart';
import '../services/weather_service.dart';
import '../features/reader/controller/reader_settings_controller.dart';
import 'app_runtime.dart';
import 'bootstrap/firebase_bootstrap.dart';
import 'theme/theme_mode_controller.dart';

final Provider<LocalStorageService> localStorageServiceProvider =
    Provider<LocalStorageService>((ProviderRef<LocalStorageService> ref) {
  return LocalStorageService();
});

final StateNotifierProvider<ThemeModeController, ThemeMode> themeModeControllerProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(ref.read(localStorageServiceProvider));
});

final Provider<ThemeMode> themeModeProvider = Provider<ThemeMode>((ProviderRef<ThemeMode> ref) {
  return ref.watch(themeModeControllerProvider);
});

final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>((ProviderRef<AppDatabase> ref) {
  return AppRuntime.database;
});

final Provider<SyncQueueRepository> syncQueueRepositoryProvider =
    Provider<SyncQueueRepository>((ProviderRef<SyncQueueRepository> ref) {
  return SyncQueueRepository(ref.read(databaseProvider));
});

final Provider<ContentRepository> contentRepositoryProvider =
    Provider<ContentRepository>((ProviderRef<ContentRepository> ref) {
  return ContentRepository(ref.read(databaseProvider));
});

final Provider<BibleRepository> bibleRepositoryProvider =
    Provider<BibleRepository>((ProviderRef<BibleRepository> ref) {
  return BibleRepository();
});

final Provider<SearchRepository> searchRepositoryProvider =
    Provider<SearchRepository>((ProviderRef<SearchRepository> ref) {
  return SearchRepository(
    ref.read(contentRepositoryProvider),
    ref.read(bibleRepositoryProvider),
  );
});

final Provider<ProgressRepository> progressRepositoryProvider =
    Provider<ProgressRepository>((ProviderRef<ProgressRepository> ref) {
  return ProgressRepository(ref.read(databaseProvider), ref.read(syncQueueRepositoryProvider));
});

final Provider<PlannerRepository> plannerRepositoryProvider =
    Provider<PlannerRepository>((ProviderRef<PlannerRepository> ref) {
  return PlannerRepository(ref.read(databaseProvider));
});

final Provider<ReflectionRepository> reflectionRepositoryProvider =
    Provider<ReflectionRepository>((ProviderRef<ReflectionRepository> ref) {
  return ReflectionRepository(ref.read(databaseProvider), ref.read(syncQueueRepositoryProvider));
});

final Provider<FavoritesRepository> favoritesRepositoryProvider =
    Provider<FavoritesRepository>((ProviderRef<FavoritesRepository> ref) {
  return FavoritesRepository(ref.read(databaseProvider), ref.read(syncQueueRepositoryProvider));
});

final Provider<SyncService> syncServiceProvider = Provider<SyncService>((ProviderRef<SyncService> ref) {
  return SyncService(
    syncQueueRepository: ref.read(syncQueueRepositoryProvider),
    firebaseEnabled: AppRuntime.firebaseEnabled,
  );
});

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ProviderRef<AuthRepository> ref) {
  return AuthRepository(
    localStorageService: ref.read(localStorageServiceProvider),
    firebaseEnabled: AppRuntime.firebaseEnabled,
  );
});

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(authRepositoryProvider), ref.read(syncServiceProvider));
});

final Provider<ChurchCourtesyService> churchCourtesyServiceProvider =
    Provider<ChurchCourtesyService>((ProviderRef<ChurchCourtesyService> ref) {
  return ChurchCourtesyService(ref.read(localStorageServiceProvider));
});

final Provider<NotificationService> notificationServiceProvider =
    Provider<NotificationService>((ProviderRef<NotificationService> ref) {
  return NotificationService();
});

final Provider<TtsService> ttsServiceProvider =
    Provider<TtsService>((ProviderRef<TtsService> ref) {
  final TtsService service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

final Provider<WeatherService> weatherServiceProvider =
    Provider<WeatherService>((ProviderRef<WeatherService> ref) {
  return WeatherService(ref.read(localStorageServiceProvider));
});

final FutureProvider<void> appBootstrapProvider = FutureProvider<void>((FutureProviderRef<void> ref) async {
  AppRuntime.firebaseEnabled = await FirebaseBootstrap.initialize();
  final AppDatabase database = await AppDatabase.open();
  AppRuntime.setDatabase(database);

  await ref.read(themeModeControllerProvider.notifier).load();
  await ref.read(readerSettingsControllerProvider.notifier).load();
  // Apply the saved TTS engine preference (engine scan runs lazily in bg).
  await ref
      .read(ttsServiceProvider)
      .setPreferredEngine(await ref.read(localStorageServiceProvider).getTtsEngine());
  await ref.read(authControllerProvider.notifier).initialize();

  final NotificationService notifications = ref.read(notificationServiceProvider);
  await notifications.initialize();
  final LocalStorageService storage = ref.read(localStorageServiceProvider);
  if (await storage.getReminderEnabled()) {
    final (int h, int m) = await storage.getReminderTime();
    await notifications.scheduleDailyVerseReminderAt(hour: h, minute: m);
  }
  await notifications.scheduleChurchCourtesyReminder();
});
