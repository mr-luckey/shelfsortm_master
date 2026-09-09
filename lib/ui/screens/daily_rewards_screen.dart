import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/progress_provider.dart';
import '../meta/meta_chrome.dart';
import '../premium/premium_tokens.dart';

class DailyRewardsScreen extends StatelessWidget {
  const DailyRewardsScreen({super.key});

  static const rewards = [
    '50 Coins',
    '1 Gem + 1 Hint',
    '100 Coins',
    '2 Gems',
    '1 Shuffle + 100 Coins',
    '3 Gems',
    'Lucky Box Cosmetic',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progress, _) {
        final p = progress.progress;
        final day = p.loginStreak.clamp(1, 7);

        return MetaBackdrop(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  const MetaTitle('Daily Rewards', size: 26)
                      .animate()
                      .fadeIn(),
                  SizedBox(height: 6.h),
                  MetaSubtitle('Streak Day $day / 7'),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10.h,
                        crossAxisSpacing: 10.w,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: 7,
                      itemBuilder: (context, i) {
                        final d = i + 1;
                        final claimed = p.claimedRewardDays.contains(d);
                        final current = d == day;
                        return MetaWoodCard(
                          padding: EdgeInsets.all(8.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Day $d',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w900,
                                  color: current
                                      ? MetaChrome.gold
                                      : MetaChrome.cream,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Image.asset(
                                '${PremiumTokens.uiRoot}/gift_reward.png',
                                width: 28.w,
                                height: 28.w,
                                errorBuilder: (context, error, stack) =>
                                    const Icon(
                                  Icons.card_giftcard,
                                  color: MetaChrome.gold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                rewards[i],
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: MetaChrome.cream.withValues(alpha: 0.9),
                                ),
                              ),
                              if (claimed)
                                Icon(
                                  Icons.check_circle,
                                  color: const Color(0xFF81C784),
                                  size: 16.sp,
                                ),
                            ],
                          ),
                        )
                            .animate(delay: (50 * i).ms)
                            .fadeIn()
                            .scale(begin: const Offset(0.92, 0.92));
                      },
                    ),
                  ),
                  MetaPrimaryButton(
                    label: 'Claim Today',
                    onPressed: () async {
                      final claimed = await progress.claimDailyReward();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            claimed < 0
                                ? 'Already claimed today!'
                                : 'Day $claimed reward claimed!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
