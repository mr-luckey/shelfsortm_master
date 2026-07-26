import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/progress_provider.dart';
import '../../services/iap_service.dart';
import '../widgets/common_widgets.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progress, _) {
        final p = progress.progress;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.background, Color(0xFFF3E5F5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Shop',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    CurrencyHud(coins: p.coins, gems: p.gems),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Earn first, pay for comfort — never paywalled levels.',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...IapService.products.map((product) {
                  final owned = product.removeAds && p.removeAds;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        product.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(product.description),
                      trailing: owned
                          ? const Text(
                              'Owned',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () async {
                                final ok = await progress.purchase(product);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Purchased ${product.title}!'
                                          : 'Purchase failed',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Text(product.priceLabel),
                            ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                const Text(
                  'Cosmetics (Coins)',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 8),
                _CosmeticTile(
                  id: 'shelf_oak_gold',
                  title: 'Golden Oak Shelf',
                  cost: 500,
                  owned: p.ownedCosmetics.contains('shelf_oak_gold'),
                  onBuy: () => progress.buyCosmetic(
                    'shelf_oak_gold',
                    coinCost: 500,
                  ),
                ),
                _CosmeticTile(
                  id: 'item_pastel',
                  title: 'Pastel Item Theme',
                  cost: 200,
                  owned: p.ownedCosmetics.contains('item_pastel'),
                  onBuy: () => progress.buyCosmetic(
                    'item_pastel',
                    coinCost: 200,
                  ),
                ),
                _CosmeticTile(
                  id: 'mia_chef',
                  title: 'Mia Chef Outfit',
                  cost: 0,
                  gemCost: 5,
                  owned: p.ownedCosmetics.contains('mia_chef'),
                  onBuy: () => progress.buyCosmetic(
                    'mia_chef',
                    gemCost: 5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CosmeticTile extends StatelessWidget {
  final String id;
  final String title;
  final int cost;
  final int gemCost;
  final bool owned;
  final VoidCallback onBuy;

  const _CosmeticTile({
    required this.id,
    required this.title,
    required this.cost,
    required this.owned,
    required this.onBuy,
    this.gemCost = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          gemCost > 0 ? '$gemCost Gems' : '$cost Coins',
        ),
        trailing: owned
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : TextButton(onPressed: onBuy, child: const Text('Buy')),
      ),
    );
  }
}
