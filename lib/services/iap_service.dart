import 'package:flutter/foundation.dart';

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
  });
}

/// Production-shaped IAP stub. Replace with Google Play Billing.
class IapService {
  static const products = [
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
    ),
    IapProduct(
      id: 'gems_75',
      title: '75 Gems',
      description: 'Best value',
      priceLabel: '\$2.99',
      priceUsd: 2.99,
      gems: 75,
    ),
    IapProduct(
      id: 'gems_130',
      title: '130 Gems',
      description: 'Large gem pack',
      priceLabel: '\$4.99',
      priceUsd: 4.99,
      gems: 130,
    ),
    IapProduct(
      id: 'gems_300',
      title: '300 Gems',
      description: 'Mega gem pack',
      priceLabel: '\$9.99',
      priceUsd: 9.99,
      gems: 300,
    ),
    IapProduct(
      id: 'daily_tools',
      title: 'Daily Tools Bundle',
      description: '2x daily tools for 7 days',
      priceLabel: '\$1.99',
      priceUsd: 1.99,
      hints: 6,
    ),
  ];

  Future<bool> purchase(IapProduct product) async {
    debugPrint('[IapService] Simulated purchase: ${product.id}');
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return true;
  }

  Future<void> restorePurchases() async {
    debugPrint('[IapService] Restore purchases stub');
  }
}
