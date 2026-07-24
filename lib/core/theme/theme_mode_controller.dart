import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage_service.dart';

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._storage) : super(ThemeMode.system);

  final LocalStorageService _storage;

  Future<void> load() async {
    final String? raw = await _storage.getThemeMode();
    if (raw == null) {
      state = ThemeMode.system;
      return;
    }

    switch (raw) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final String raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _storage.setThemeMode(raw);
  }
}
