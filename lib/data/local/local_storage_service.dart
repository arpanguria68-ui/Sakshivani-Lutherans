import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _themeModeKey = 'settings.theme_mode';
  static const String _churchModeEnabledKey = 'settings.church_mode_enabled';
  static const String _churchModePromptCooldownUntilKey =
      'settings.church_mode_cooldown_until';
  static const String _courtesyVolumeLevelKey = 'settings.courtesy_volume_level';
  static const String _localGuestUidKey = 'auth.local_guest_uid';
  static const String _songReaderFontSizeKey = 'settings.song_reader_font_size';
  static const String _readerSettingsKey = 'settings.reader_settings_json';
  static const String _reminderEnabledKey = 'settings.daily_reminder_enabled';
  static const String _reminderHourKey = 'settings.daily_reminder_hour';
  static const String _reminderMinuteKey = 'settings.daily_reminder_minute';
  static const String _bibleLastReadKey = 'bible.last_read';
  static const String _bibleHistoryKey = 'bible.history';
  static const String _weatherCacheKey = 'weather.cache';
  static const String _weatherCityKey = 'weather.manual_city';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<String?> getThemeMode() async {
    return (await _prefs).getString(_themeModeKey);
  }

  Future<void> setThemeMode(String value) async {
    await (await _prefs).setString(_themeModeKey, value);
  }

  Future<bool> getChurchModeEnabled() async {
    return (await _prefs).getBool(_churchModeEnabledKey) ?? true;
  }

  Future<void> setChurchModeEnabled(bool enabled) async {
    await (await _prefs).setBool(_churchModeEnabledKey, enabled);
  }

  Future<DateTime?> getCourtesyCooldownUntil() async {
    final String? iso = (await _prefs).getString(_churchModePromptCooldownUntilKey);
    if (iso == null || iso.isEmpty) {
      return null;
    }
    return DateTime.tryParse(iso);
  }

  Future<void> setCourtesyCooldownUntil(DateTime? value) async {
    final prefs = await _prefs;
    if (value == null) {
      await prefs.remove(_churchModePromptCooldownUntilKey);
      return;
    }
    await prefs.setString(_churchModePromptCooldownUntilKey, value.toIso8601String());
  }

  Future<double> getCourtesyVolumeLevel() async {
    return (await _prefs).getDouble(_courtesyVolumeLevelKey) ?? 0.20;
  }

  Future<void> setCourtesyVolumeLevel(double value) async {
    await (await _prefs).setDouble(_courtesyVolumeLevelKey, value);
  }

  Future<String?> getLocalGuestUid() async {
    return (await _prefs).getString(_localGuestUidKey);
  }

  Future<void> setLocalGuestUid(String uid) async {
    await (await _prefs).setString(_localGuestUidKey, uid);
  }

  Future<double> getSongReaderFontSize() async {
    return (await _prefs).getDouble(_songReaderFontSizeKey) ?? 20;
  }

  Future<void> setSongReaderFontSize(double value) async {
    await (await _prefs).setDouble(_songReaderFontSizeKey, value);
  }

  Future<String?> getReaderSettingsJson() async {
    return (await _prefs).getString(_readerSettingsKey);
  }

  Future<void> setReaderSettingsJson(String json) async {
    await (await _prefs).setString(_readerSettingsKey, json);
  }

  Future<bool> getReminderEnabled() async {
    return (await _prefs).getBool(_reminderEnabledKey) ?? true;
  }

  Future<void> setReminderEnabled(bool v) async {
    await (await _prefs).setBool(_reminderEnabledKey, v);
  }

  /// Daily reminder time as (hour, minute); defaults to 06:30.
  Future<(int, int)> getReminderTime() async {
    final prefs = await _prefs;
    return (prefs.getInt(_reminderHourKey) ?? 6, prefs.getInt(_reminderMinuteKey) ?? 30);
  }

  Future<void> setReminderTime(int hour, int minute) async {
    final prefs = await _prefs;
    await prefs.setInt(_reminderHourKey, hour);
    await prefs.setInt(_reminderMinuteKey, minute);
  }

  // ─── Bible last-read + reading history ─────────────────────────────────────

  /// Last read position as {language, bookIndex, chapterIndex}, or null.
  Future<Map<String, dynamic>?> getBibleLastRead() async {
    final String? raw = (await _prefs).getString(_bibleLastReadKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setBibleLastRead(String language, int bookIndex, int chapterIndex) async {
    await (await _prefs).setString(
      _bibleLastReadKey,
      jsonEncode(<String, dynamic>{
        'language': language,
        'bookIndex': bookIndex,
        'chapterIndex': chapterIndex,
      }),
    );
  }

  /// Recent chapters, most-recent-first, de-duplicated, capped at 20.
  Future<List<Map<String, dynamic>>> getBibleHistory() async {
    final String? raw = (await _prefs).getString(_bibleHistoryKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().toList(growable: false);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> pushBibleHistory(String language, int bookIndex, int chapterIndex) async {
    final List<Map<String, dynamic>> history = await getBibleHistory();
    history.removeWhere((Map<String, dynamic> e) =>
        e['language'] == language &&
        e['bookIndex'] == bookIndex &&
        e['chapterIndex'] == chapterIndex);
    history.insert(0, <String, dynamic>{
      'language': language,
      'bookIndex': bookIndex,
      'chapterIndex': chapterIndex,
      'ts': DateTime.now().toIso8601String(),
    });
    final List<Map<String, dynamic>> capped =
        history.length > 20 ? history.sublist(0, 20) : history;
    await (await _prefs).setString(_bibleHistoryKey, jsonEncode(capped));
  }

  // ─── Weather ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getWeatherCache() async {
    final String? raw = (await _prefs).getString(_weatherCacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setWeatherCache(Map<String, dynamic> data) async {
    await (await _prefs).setString(_weatherCacheKey, jsonEncode(data));
  }

  Future<String?> getManualCity() async {
    return (await _prefs).getString(_weatherCityKey);
  }

  Future<void> setManualCity(String? city) async {
    final prefs = await _prefs;
    if (city == null || city.isEmpty) {
      await prefs.remove(_weatherCityKey);
    } else {
      await prefs.setString(_weatherCityKey, city);
    }
  }
}
