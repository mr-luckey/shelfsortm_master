import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/progress_provider.dart';

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

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.background, Color(0xFFFFE0B2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Daily Login Rewards',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Streak Day $day / 7',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: 7,
                      itemBuilder: (context, i) {
                        final d = i + 1;
                        final claimed = p.claimedRewardDays.contains(d);
                        final current = d == day;
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: claimed
                                ? LinearGradient(
                                    colors: [
                                      AppColors.success.withValues(alpha: 0.3),
                                      AppColors.success.withValues(alpha: 0.1),
                                    ],
                                  )
                                : AppColors.primaryGradient,
                            border: current
                                ? Border.all(color: AppColors.secondary, width: 3)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Day $d',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: claimed ? AppColors.success : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                rewards[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: claimed
                                      ? AppColors.textDark
                                      : Colors.white,
                                ),
                              ),
                              if (claimed)
                                const Icon(Icons.check_circle,
                                    color: AppColors.success, size: 18),
                            ],
                          ),
                        ).animate(delay: (60 * i).ms).fadeIn().scale(
                              begin: const Offset(0.9, 0.9),
                            );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
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
                      child: const Text('Claim Today'),
                    ),
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
