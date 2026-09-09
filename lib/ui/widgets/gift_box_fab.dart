import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/progress_provider.dart';
import '../../services/ad_service.dart';
import '../../services/analytics_service.dart';
import '../../services/gift_loot.dart';
import '../meta/meta_chrome.dart';
import '../meta/praise_burst.dart';
import '../premium/premium_tokens.dart';

/// Floating gift box. Hidden offline / remove-ads.
/// First tap: loading + preload. Second tap: rewarded ad → random loot.
class GiftBoxFab extends StatefulWidget {
  final GiftLootPool pool;
  final Future<void> Function(GiftLoot loot)? onLoot;
  final double size;

  const GiftBoxFab({
    super.key,
    this.pool = GiftLootPool.meta,
    this.onLoot,
    this.size = 64,
  });

  @override
  State<GiftBoxFab> createState() => _GiftBoxFabState();
}

class _GiftBoxFabState extends State<GiftBoxFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat;
  late final Animation<double> _scale;
  int _tapCount = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _beat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 16,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 38,
      ),
    ]).animate(_beat);
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_busy) return;
    final ads = context.read<AdService>();
    if (!ads.adsUiEnabled || ads.isFullScreenShowing) return;

    final progress = context.read<ProgressProvider>();
    if (progress.progress.removeAds) return;

    _tapCount++;
    if (_tapCount == 1) {
      setState(() => _busy = true);
      await ads.preloadRewarded(placement: 'gift_box');
      if (!mounted) return;
      setState(() => _busy = false);
      return;
    }

    setState(() => _busy = true);
    final outcome = await ads.showRewardedAd(placement: 'gift_box');
    if (!mounted) return;

    if (outcome == RewardedAdOutcome.earned) {
      final analytics = context.read<AnalyticsService>();
      unawaited(
        analytics.logRewardedAdCompleted(
          placement: 'gift_box',
          source: widget.pool.name,
        ),
      );
      final loot = GiftLootTables.roll(widget.pool);
      if (widget.pool == GiftLootPool.meta) {
        await progress.applyMetaGiftLoot(loot);
      } else {
        unawaited(
          analytics.logRewardClaimed(
            rewardType: switch (loot) {
              CoinsLoot() => 'coins',
              GemsLoot() => 'gems',
              DoubleCoinsLoot() => 'double_coins',
              GameplayHintLoot() => 'hint',
              GameplayFreezeLoot() => 'freeze',
              GameplayTimeLoot() => 'extra_time',
            },
            source: 'gift_box',
          ),
        );
      }
      if (mounted) {
        await widget.onLoot?.call(loot);
      }
      if (mounted) {
        await showGiftRewardPopup(context, loot);
      }
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _tapCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdService>();
    final removeAds = context.watch<ProgressProvider>().progress.removeAds;
    if (!ads.adsUiEnabled || removeAds) {
      return const SizedBox.shrink();
    }

    final s = widget.size.w;

    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _busy ? null : _onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: s,
            height: s,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  '${PremiumTokens.uiRoot}/gift_box.png',
                  width: s,
                  height: s,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
                if (_busy)
                  Container(
                    width: s,
                    height: s,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular((widget.size / 4).r),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4.w,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showGiftRewardPopup(BuildContext context, GiftLoot loot) {
  return MetaPopupScope.show<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return MetaWoodCard(
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You won!',
              style: GoogleFonts.nunito(
                color: MetaChrome.gold,
                fontWeight: FontWeight.w900,
                fontSize: 22.sp,
              ),
            ),
            SizedBox(height: 16.h),
            _GiftRewardVisual(loot: loot),
            SizedBox(height: 14.h),
            Text(
              loot.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: MetaChrome.cream,
                fontWeight: FontWeight.w800,
                fontSize: 20.sp,
              ),
            ),
            SizedBox(height: 18.h),
            MetaPrimaryButton(
              label: 'Collect',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    },
  );
}

class _GiftRewardVisual extends StatelessWidget {
  final GiftLoot loot;

  const _GiftRewardVisual({required this.loot});

  @override
  Widget build(BuildContext context) {
    final asset = switch (loot) {
      CoinsLoot() || DoubleCoinsLoot() =>
        '${PremiumTokens.uiRoot}/coin.webp',
      GemsLoot() => '${PremiumTokens.uiRoot}/gem.webp',
      GameplayTimeLoot() => '${PremiumTokens.uiRoot}/hourglass.png',
      GameplayHintLoot() || GameplayFreezeLoot() => null,
    };

    if (asset != null) {
      return Image.asset(
        asset,
        width: 72.w,
        height: 72.w,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stack) => Icon(
          switch (loot) {
            CoinsLoot() || DoubleCoinsLoot() => Icons.monetization_on,
            GemsLoot() => Icons.diamond,
            _ => Icons.card_giftcard_rounded,
          },
          size: 64.sp,
          color: MetaChrome.gold,
        ),
      );
    }

    final (icon, color) = switch (loot) {
      GameplayHintLoot() => (Icons.lightbulb_rounded, PremiumTokens.hintOrange),
      GameplayFreezeLoot() => (Icons.ac_unit_rounded, PremiumTokens.freezeGreen),
      _ => (Icons.card_giftcard_rounded, MetaChrome.gold),
    };

    return Icon(icon, size: 72.sp, color: color);
  }
}
