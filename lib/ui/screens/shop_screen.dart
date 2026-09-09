import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
              padding: EdgeInsets.all(16.w),
              children: [
                Row(
                  children: [
                    const Expanded(child: MetaTitle('Shop', size: 26)),
                    CurrencyHud(coins: p.coins, gems: p.gems),
                  ],
                ).animate().fadeIn(),
                SizedBox(height: 8.h),
                MetaSubtitle(
                  'Earn first, pay for comfort — never paywalled levels.',
                ),
                SizedBox(height: 12.h),
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
                SizedBox(height: 16.h),
                ...IapService.products.map((product) {
                  final owned = product.removeAds && p.removeAds;
                  return MetaWoodCard(
                    margin: EdgeInsets.only(bottom: 12.h),
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
                                  fontSize: 16.sp,
                                  color: MetaChrome.cream,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                product.description,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                  color: MetaChrome.cream.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
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
                            height: 40.h,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: MetaChrome.gold,
                                  width: 1.2.w,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
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
                SizedBox(height: 8.h),
                Text(
                  'Cosmetics',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 18.sp,
                    color: MetaChrome.cream,
                  ),
                ),
                SizedBox(height: 8.h),
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
      margin: EdgeInsets.only(bottom: 10.h),
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
                    fontSize: 12.sp,
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
