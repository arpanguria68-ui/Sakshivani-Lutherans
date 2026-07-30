import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/local_storage_service.dart';

class OnboardingController extends StateNotifier<bool> {
  OnboardingController(this._storage) : super(false);

  final LocalStorageService _storage;

  Future<void> load() async {
    state = await _storage.getOnboarded();
  }

  Future<void> complete() async {
    state = true;
    await _storage.setOnboarded(true);
  }

  /// Returns the app to a first-run state — used by "reset app" and account
  /// deletion. The router redirects to /onboarding as soon as this lands.
  Future<void> reset() async {
    state = false;
    await _storage.setOnboarded(false);
  }
}
