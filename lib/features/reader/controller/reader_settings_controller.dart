import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/local/local_storage_service.dart';
import '../domain/reader_settings.dart';

/// Persists [ReaderSettings] to shared preferences and exposes them app-wide,
/// so Songs / Catechism / Bible readers share one reading configuration.
class ReaderSettingsController extends StateNotifier<ReaderSettings> {
  ReaderSettingsController(this._storage) : super(const ReaderSettings());

  final LocalStorageService _storage;

  Future<void> load() async {
    final String? json = await _storage.getReaderSettingsJson();
    state = ReaderSettings.decode(json);
  }

  Future<void> update(ReaderSettings next) async {
    state = next;
    await _storage.setReaderSettingsJson(next.encode());
  }

  Future<void> setFontSize(double v) => update(state.copyWith(
        fontSize: v.clamp(ReaderSettings.minFontSize, ReaderSettings.maxFontSize),
      ));
  Future<void> setLineHeight(double v) => update(state.copyWith(lineHeight: v));
  Future<void> setLetterSpacing(double v) => update(state.copyWith(letterSpacing: v));
  Future<void> setWordSpacing(double v) => update(state.copyWith(wordSpacing: v));
  Future<void> setFont(ReaderFontFamily f) => update(state.copyWith(font: f));
  Future<void> setAlign(ReaderAlign a) => update(state.copyWith(align: a));
  Future<void> setTheme(ReaderTheme t) => update(state.copyWith(theme: t));
  Future<void> setPaginated(bool p) => update(state.copyWith(paginated: p));
  Future<void> setPaperTexture(bool p) => update(state.copyWith(paperTexture: p));
  Future<void> setPageTurnSound(bool p) => update(state.copyWith(pageTurnSound: p));
  Future<void> setTtsRate(double v) => update(state.copyWith(ttsRate: v));
}

final readerSettingsControllerProvider =
    StateNotifierProvider<ReaderSettingsController, ReaderSettings>((ref) {
  return ReaderSettingsController(ref.read(localStorageServiceProvider));
});
