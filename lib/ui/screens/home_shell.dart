import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/goods_sort_theme.dart';
import '../../data/level_repository.dart';
import '../../models/player_progress.dart';
import '../../models/theme_room.dart';
import '../../providers/progress_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/goods_emoji.dart';
import '../widgets/store_background.dart';
import 'asmr_mode_screen.dart';
import 'daily_rewards_screen.dart';
import 'level_intro_sheet.dart';
import 'level_map_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

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
        indicatorColor: GoodsSortTheme.playGreen.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_rounded),
            selectedIcon: Icon(Icons.storefront_rounded, color: GoodsSortTheme.playGreen),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_rounded),
            selectedIcon: Icon(Icons.map_rounded, color: GoodsSortTheme.playGreen),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_rounded),
            selectedIcon: Icon(Icons.card_giftcard_rounded, color: GoodsSortTheme.playGreen),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_rounded),
            selectedIcon: Icon(Icons.shopping_bag_rounded, color: GoodsSortTheme.playGreen),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: GoodsSortTheme.playGreen),
            label: 'Profile',
          ),
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
        final maxLevel = LevelRepository.instance.totalLevels;

        return Stack(
          fit: StackFit.expand,
          children: [
            StoreBackground(
              colors: GoodsSortTheme.homeGradient.colors,
              moodType: theme.iconType,
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              EmojiImage(type: theme.iconType, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                p.playerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        CurrencyHud(coins: p.coins, gems: p.gems, compact: true),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Goods Sort',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E7D32),
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Triple Match • Organize • Relax',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _GoodsSortShowcase(theme: theme),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: GoodsSortTheme.playGreen,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: GoodsSortTheme.playGreen.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'LEVEL ${p.currentLevel.clamp(1, maxLevel)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        EmojiImage(type: theme.iconType, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          theme.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GlowPlayButton(
                      onPressed: () {
                        launchLevel(
                          context,
                          levelId: p.currentLevel.clamp(1, maxLevel),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _QuickChip(
                          icon: Icons.star_rounded,
                          label: '${p.totalStars} Stars',
                          color: const Color(0xFFFFB300),
                        ),
                        const SizedBox(width: 10),
                        _QuickChip(
                          icon: Icons.emoji_events_rounded,
                          label: '${_levelClears(p)} Clears',
                          color: GoodsSortTheme.playGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _AsmrModeBanner(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AsmrModeScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  int _levelClears(PlayerProgress p) =>
      p.levels.values.fold<int>(0, (n, l) => n + l.playCount);
}

class _GoodsSortShowcase extends StatelessWidget {
  final ThemeRoom theme;

  const _GoodsSortShowcase({required this.theme});

  @override
  Widget build(BuildContext context) {
    final types = theme.itemTypes;
    const colors = ['red', 'blue', 'green', 'yellow', 'purple'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: GoodsSortTheme.playGreen.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              return PreviewEmoji(
                type: types[i % types.length],
                color: colors[i % colors.length],
                size: 52,
              );
            }),
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              return PreviewEmoji(
                type: types[(i + 1) % types.length],
                color: colors[(i + 2) % colors.length],
                size: 48,
              );
            }),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.08);
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AsmrModeBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _AsmrModeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2A2A3A),
              Color(0xFF121218),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headphones_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'ASMR Mode',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 15,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
