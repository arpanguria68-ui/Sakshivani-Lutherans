import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/local_storage_service.dart';
import '../domain/verse_background_settings.dart';

class VerseBackgroundController extends StateNotifier<VerseBackgroundSettings> {
  VerseBackgroundController(this._storage) : super(VerseBackgroundSettings.initial());

  final LocalStorageService _storage;

  Future<void> load() async {
    final String? modeRaw = await _storage.getVerseBackgroundMode();
    final List<String>? order = await _storage.getVerseBackgroundOrder();
    final int? hours = await _storage.getVerseBackgroundRotateHours();
    final String? manual = await _storage.getVerseBackgroundManualImage();

    state = VerseBackgroundSettings(
      mode: modeRaw == 'manual' ? VerseBackgroundMode.manual : VerseBackgroundMode.auto,
      order: (order == null || order.isEmpty) ? VerseBackgroundSettings.defaultOrder : order,
      rotateHours: hours ?? VerseBackgroundSettings.defaultRotateHours,
      manualImage: manual ?? VerseBackgroundSettings.defaultOrder.first,
    );
  }

  Future<void> setMode(VerseBackgroundMode mode) async {
    state = state.copyWith(mode: mode);
    await _storage.setVerseBackgroundMode(mode == VerseBackgroundMode.manual ? 'manual' : 'auto');
  }

  Future<void> setManualImage(String assetPath) async {
    state = state.copyWith(manualImage: assetPath);
    await _storage.setVerseBackgroundManualImage(assetPath);
  }

  Future<void> setRotateHours(int hours) async {
    state = state.copyWith(rotateHours: hours);
    await _storage.setVerseBackgroundRotateHours(hours);
  }

  Future<void> setOrder(List<String> order) async {
    state = state.copyWith(order: order);
    await _storage.setVerseBackgroundOrder(order);
  }
}
