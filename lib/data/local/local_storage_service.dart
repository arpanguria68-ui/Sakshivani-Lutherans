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
}
