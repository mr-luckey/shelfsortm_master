import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/progress_provider.dart';
import '../../services/iap_service.dart';
import '../meta/meta_chrome.dart';
import '../widgets/common_widgets.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progress, _) {
        final p = progress.progress;
        return MetaBackdrop(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Expanded(child: MetaTitle('Shop', size: 26)),
                    CurrencyHud(coins: p.coins, gems: p.gems),
                  ],
                ).animate().fadeIn(),
                const SizedBox(height: 8),
                MetaSubtitle(
                  'Earn first, pay for comfort — never paywalled levels.',
                ),
                const SizedBox(height: 12),
                MetaSecondaryButton(
                  label: 'Restore Purchases',
                  onPressed: () async {
                    await progress.restorePurchases();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Purchases restored'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ...IapService.products.map((product) {
                  final owned = product.removeAds && p.removeAds;
                  return MetaWoodCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: MetaChrome.cream,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.description,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: MetaChrome.cream.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (owned)
                          Text(
                            'Owned',
                            style: GoogleFonts.nunito(
                              color: const Color(0xFF81C784),
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        else
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: MetaChrome.gold,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.04);
                }),
                const SizedBox(height: 8),
                Text(
                  'Cosmetics',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: MetaChrome.cream,
                  ),
                ),
                const SizedBox(height: 8),
                _CosmeticTile(
                  title: 'Golden Oak Shelf',
                  costLabel: '500 Coins',
                  owned: p.ownedCosmetics.contains('shelf_oak_gold'),
                  onBuy: () => progress.buyCosmetic(
                    'shelf_oak_gold',
                    coinCost: 500,
                  ),
                ),
                _CosmeticTile(
                  title: 'Pastel Item Theme',
                  costLabel: '200 Coins',
                  owned: p.ownedCosmetics.contains('item_pastel'),
                  onBuy: () => progress.buyCosmetic(
                    'item_pastel',
                    coinCost: 200,
                  ),
                ),
                _CosmeticTile(
                  title: 'Mia Chef Outfit',
                  costLabel: '5 Gems',
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
  final String title;
  final String costLabel;
  final bool owned;
  final VoidCallback onBuy;

  const _CosmeticTile({
    required this.title,
    required this.costLabel,
    required this.owned,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return MetaWoodCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    color: MetaChrome.cream,
                  ),
                ),
                Text(
                  costLabel,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: MetaChrome.gold,
                  ),
                ),
              ],
            ),
          ),
          if (owned)
            const Icon(Icons.check_circle, color: Color(0xFF81C784))
          else
            TextButton(
              onPressed: onBuy,
              child: Text(
                'Buy',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  color: MetaChrome.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
