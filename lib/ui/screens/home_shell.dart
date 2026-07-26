import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../models/theme_room.dart';
import '../../providers/progress_provider.dart';
import '../widgets/common_widgets.dart';
import 'daily_rewards_screen.dart';
import 'level_intro_sheet.dart';
import 'level_map_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'tutorial_overlay.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ProgressProvider>();
      if (!p.progress.tutorialDone) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const TutorialOverlay(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const LevelMapScreen(),
      const DailyRewardsScreen(),
      const ShopScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map_rounded), label: 'Map'),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_rounded),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_rounded),
            label: 'Shop',
          ),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progress, _) {
        final p = progress.progress;
        final theme = ThemeRoom.forLevel(p.currentLevel);

        return Container(
          decoration: BoxDecoration(gradient: AppColors.themeGradient(theme.id)),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      const MiaAvatar(size: 48),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.playerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      CurrencyHud(coins: p.coins, gems: p.gems),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Storefront(theme: theme)
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.1),
                          const SizedBox(height: 28),
                          Text(
                            "Mia's Magical Store",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${theme.emoji} ${theme.name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sort shelves • Match 3 • Use buffers',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 28),
                          GlowPlayButton(
                            onPressed: () {
                              showLevelIntro(
                                context,
                                levelId: p.currentLevel.clamp(
                                  1,
                                  50,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _DailyBanner(
                            claimed: p.dailyChallengeCompleted,
                            onTap: () {
                              showLevelIntro(
                                context,
                                levelId: p.currentLevel,
                                daily: true,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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

class _Storefront extends StatelessWidget {
  final ThemeRoom theme;

  const _Storefront({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            AppColors.primary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Text(
              theme.emoji,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 56),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -6, duration: 1400.ms),
          ),
          Positioned(
            bottom: 24,
            left: 40,
            right: 40,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.wood,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (i) => Container(
                    width: 36,
                    height: 44,
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: [
                        AppColors.itemRed,
                        AppColors.itemBlue,
                        AppColors.itemGreen,
                        AppColors.itemYellow,
                      ][i],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  )
                      .animate(delay: (100 * i).ms)
                      .fadeIn()
                      .slideY(begin: 0.4),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 18,
            child: const Text('🕊️', style: TextStyle(fontSize: 22))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(begin: 0, end: 8, duration: 2000.ms),
          ),
        ],
      ),
    );
  }
}

class _DailyBanner extends StatelessWidget {
  final bool claimed;
  final VoidCallback onTap;

  const _DailyBanner({required this.claimed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: claimed ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: claimed ? Colors.grey.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: claimed ? Colors.grey : AppColors.primary,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              color: claimed ? Colors.grey : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              claimed ? 'Daily Challenge done' : 'Daily Challenge',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: claimed ? Colors.grey : AppColors.textDark,
              ),
            ),
          ],
        ),
      )
          .animate(
            target: claimed ? 0 : 1,
            onPlay: (c) {
              if (!claimed) c.repeat(reverse: true);
            },
          )
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.03, 1.03),
            duration: 900.ms,
          ),
    );
  }
}
