import 'package:app_settings/app_settings.dart';
import 'package:flutter/services.dart';
import 'package:volume_controller/volume_controller.dart';

import '../data/local/local_storage_service.dart';

class ChurchCourtesyService {
  ChurchCourtesyService(this._storageService);

  final LocalStorageService _storageService;

  double? _lastVolumeBeforeCourtesy;

  Future<bool> shouldPromptNow() async {
    final bool enabled = await _storageService.getChurchModeEnabled();
    if (!enabled) {
      return false;
    }

    if (!_isLikelyServiceWindow(DateTime.now())) {
      return false;
    }

    final DateTime? cooldown = await _storageService.getCourtesyCooldownUntil();
    if (cooldown == null) {
      return true;
    }

    return DateTime.now().isAfter(cooldown);
  }

  Future<void> snoozePrompt(Duration duration) async {
    final DateTime until = DateTime.now().add(duration);
    await _storageService.setCourtesyCooldownUntil(until);
  }

  Future<void> lowerVolumeForService() async {
    _lastVolumeBeforeCourtesy ??= await VolumeController().getVolume();
    final double target = await _storageService.getCourtesyVolumeLevel();
    VolumeController().setVolume(
      target.clamp(0.0, 1.0).toDouble(),
      showSystemUI: false,
    );
  }

  Future<void> restoreVolume() async {
    final double? previous = _lastVolumeBeforeCourtesy;
    if (previous == null) {
      return;
    }
    VolumeController().setVolume(
      previous.clamp(0.0, 1.0).toDouble(),
      showSystemUI: false,
    );
    _lastVolumeBeforeCourtesy = null;
  }

  Future<void> openDoNotDisturbSettings() async {
    try {
      await AppSettings.openAppSettings();
    } on PlatformException {
      await AppSettings.openAppSettings();
    }
  }

  bool _isLikelyServiceWindow(DateTime now) {
    final int mins = now.hour * 60 + now.minute;

    if (now.weekday == DateTime.saturday) {
      return mins >= 17 * 60 + 30 && mins <= 21 * 60;
    }
    if (now.weekday == DateTime.sunday) {
      return mins >= 7 * 60 + 30 && mins <= 13 * 60;
    }
    return false;
  }
}
