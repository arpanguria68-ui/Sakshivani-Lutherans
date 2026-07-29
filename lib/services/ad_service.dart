import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/constants/app_constants.dart';
import '../data/local/local_storage_service.dart';

/// Owns AdMob init (incl. UMP consent) and interstitial preloading.
/// Banner ads are built directly by [AdBannerWidget], which asks this
/// service whether ads should show at all before creating one.
class AdService {
  AdService(this._storage);

  final LocalStorageService _storage;
  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;

  /// Ads are suppressed once the user has bought "Remove Ads / Supporter".
  Future<bool> shouldShowAds() async => !(await _storage.getAdFree());

  /// Initializes the Mobile Ads SDK and runs the UMP (EEA/UK) consent flow
  /// if applicable. Safe to call unconditionally at app startup — both the
  /// SDK init and the consent request are no-ops/fast when not required.
  Future<void> initialize() async {
    if (!await shouldShowAds()) {
      return;
    }
    try {
      await _requestConsent();
      await MobileAds.instance.initialize();
      unawaited(_preloadInterstitial());
    } catch (_) {
      // Ads are non-critical; a failed init just means no ads this session.
    }
  }

  Future<void> _requestConsent() async {
    final ConsentRequestParameters params = ConsentRequestParameters();
    final Completer<void> done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          try {
            await _loadAndShowConsentFormIfRequired();
          } catch (_) {
            // Best-effort: proceed without a form rather than blocking startup.
          }
        }
        if (!done.isCompleted) done.complete();
      },
      (FormError error) {
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
  }

  Future<void> _loadAndShowConsentFormIfRequired() async {
    final Completer<void> done = Completer<void>();
    ConsentForm.loadConsentForm(
      (ConsentForm form) async {
        final ConsentStatus status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          form.show((FormError? _) {
            if (!done.isCompleted) done.complete();
          });
        } else {
          if (!done.isCompleted) done.complete();
        }
      },
      (FormError error) {
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
  }

  Future<void> _preloadInterstitial() async {
    if (_loadingInterstitial || _interstitial != null || !await shouldShowAds()) {
      return;
    }
    _loadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: AppConstants.admobInterstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _loadingInterstitial = false;
        },
      ),
    );
  }

  /// Shows a preloaded interstitial if one is ready and the user hasn't gone
  /// ad-free, then starts preloading the next one. A no-op (never blocks
  /// the caller's flow) if no ad is ready yet — interstitials are a bonus,
  /// never a gate on app functionality.
  Future<void> showInterstitialIfReady() async {
    if (!await shouldShowAds()) {
      return;
    }
    final InterstitialAd? ad = _interstitial;
    if (ad == null) {
      unawaited(_preloadInterstitial());
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        unawaited(_preloadInterstitial());
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        unawaited(_preloadInterstitial());
      },
    );
    await ad.show();
  }

  void dispose() {
    _interstitial?.dispose();
    _interstitial = null;
  }
}
