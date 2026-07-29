import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/constants/app_constants.dart';
import '../data/local/local_storage_service.dart';

/// Wraps Google Play Billing (via `in_app_purchase`) for the single
/// "Remove Ads / Supporter" non-consumable product. Purchases (and
/// restores) flip a local `ad_free` flag that [AdService] checks before
/// showing anything.
class PurchaseService {
  PurchaseService(this._storage);

  final LocalStorageService _storage;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _removeAdsProduct;
  bool _storeAvailable = false;

  ProductDetails? get removeAdsProduct => _removeAdsProduct;
  bool get storeAvailable => _storeAvailable;

  Future<bool> get isAdFree => _storage.getAdFree();

  Future<void> initialize() async {
    _storeAvailable = await _iap.isAvailable();
    if (!_storeAvailable) {
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object _) {},
    );

    try {
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(<String>{AppConstants.iapRemoveAdsProductId});
      if (response.productDetails.isNotEmpty) {
        _removeAdsProduct = response.productDetails.first;
      }
    } catch (_) {
      // Store lookup is best-effort; the settings screen falls back to a
      // disabled/loading state if the product never resolves.
    }
  }

  Future<void> buyRemoveAds() async {
    final ProductDetails? product = _removeAdsProduct;
    if (product == null) {
      return;
    }
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      return;
    }
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      if (purchase.productID == AppConstants.iapRemoveAdsProductId &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        await _storage.setAdFree(true);
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
