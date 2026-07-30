import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IapProduct {
  final String id;
  final String title;
  final String description;
  final String priceLabel;
  final double priceUsd;
  final int gems;
  final int coins;
  final int hints;
  final bool removeAds;
  final bool isOneTime;
  final bool consumable;

  const IapProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.priceLabel,
    required this.priceUsd,
    this.gems = 0,
    this.coins = 0,
    this.hints = 0,
    this.removeAds = false,
    this.isOneTime = false,
    this.consumable = false,
  });

  IapProduct withPrice(String label) => IapProduct(
        id: id,
        title: title,
        description: description,
        priceLabel: label,
        priceUsd: priceUsd,
        gems: gems,
        coins: coins,
        hints: hints,
        removeAds: removeAds,
        isOneTime: isOneTime,
        consumable: consumable,
      );
}

/// Google Play Billing via in_app_purchase; simulates on unsupported platforms.
class IapService {
  static const catalog = [
    IapProduct(
      id: 'remove_ads',
      title: 'Remove Ads',
      description: 'Remove map banner ads forever',
      priceLabel: '\$2.99',
      priceUsd: 2.99,
      removeAds: true,
      isOneTime: true,
    ),
    IapProduct(
      id: 'starter_bundle',
      title: 'Starter Bundle',
      description: '20 Gems + 50 Coins + 5 Hints',
      priceLabel: '\$0.99',
      priceUsd: 0.99,
      gems: 20,
      coins: 50,
      hints: 5,
      isOneTime: true,
    ),
    IapProduct(
      id: 'gems_20',
      title: '20 Gems',
      description: 'Small gem pack',
      priceLabel: '\$0.99',
      priceUsd: 0.99,
      gems: 20,
      consumable: true,
    ),
    IapProduct(
      id: 'gems_75',
      title: '75 Gems',
      description: 'Best value',
      priceLabel: '\$2.99',
      priceUsd: 2.99,
      gems: 75,
      consumable: true,
    ),
    IapProduct(
      id: 'gems_130',
      title: '130 Gems',
      description: 'Large gem pack',
      priceLabel: '\$4.99',
      priceUsd: 4.99,
      gems: 130,
      consumable: true,
    ),
    IapProduct(
      id: 'gems_300',
      title: '300 Gems',
      description: 'Mega gem pack',
      priceLabel: '\$9.99',
      priceUsd: 9.99,
      gems: 300,
      consumable: true,
    ),
    IapProduct(
      id: 'daily_tools',
      title: 'Daily Tools Bundle',
      description: '2x daily tools for 7 days',
      priceLabel: '\$1.99',
      priceUsd: 1.99,
      hints: 6,
      consumable: true,
    ),
  ];

  static List<IapProduct> get products => List.unmodifiable(_displayProducts);
  static final List<IapProduct> _displayProducts = List.from(catalog);

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _available = false;
  final Map<String, ProductDetails> _store = {};
  Completer<bool>? _purchaseCompleter;
  String? _pendingProductId;

  bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!isSupported) return;
    _available = await _iap.isAvailable();
    if (!_available) return;

    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (e) {
      debugPrint('[IapService] purchase stream error: $e');
      _purchaseCompleter?.complete(false);
      _purchaseCompleter = null;
    });

    final ids = catalog.map((p) => p.id).toSet();
    final response = await _iap.queryProductDetails(ids);
    if (response.error != null) {
      debugPrint('[IapService] query error: ${response.error}');
    }
    for (final d in response.productDetails) {
      _store[d.id] = d;
    }
    _syncDisplayPrices();
  }

  void _syncDisplayPrices() {
    for (var i = 0; i < _displayProducts.length; i++) {
      final p = _displayProducts[i];
      final d = _store[p.id];
      if (d != null) {
        _displayProducts[i] = p.withPrice(d.price);
      }
    }
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;

      final ok = purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored;

      if (ok && _pendingProductId == purchase.productID) {
        _purchaseCompleter?.complete(true);
        _purchaseCompleter = null;
      } else if (purchase.status == PurchaseStatus.error) {
        _purchaseCompleter?.complete(false);
        _purchaseCompleter = null;
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<bool> purchase(IapProduct product) async {
    if (!_available || !_store.containsKey(product.id)) {
      debugPrint('[IapService] simulated purchase: ${product.id}');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return true;
    }

    _pendingProductId = product.id;
    _purchaseCompleter = Completer<bool>();
    final details = _store[product.id]!;

    final param = PurchaseParam(productDetails: details);
    if (product.consumable) {
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }

    return _purchaseCompleter!.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () => false,
    );
  }

  Future<void> restorePurchases() async {
    if (!_available) {
      debugPrint('[IapService] restore stub');
      return;
    }
    await _iap.restorePurchases();
  }

  void dispose() {
    _sub?.cancel();
  }
}
