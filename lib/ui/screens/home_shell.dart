import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/level_repository.dart';
import '../../models/player_progress.dart';
import '../../providers/progress_provider.dart';
import '../../bloc/audio_cubit.dart';
import '../meta/meta_chrome.dart';
import '../premium/premium_tokens.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/common_widgets.dart';
import '../widgets/gift_box_fab.dart';
import '../../services/gift_loot.dart';
import 'asmr_mode_screen.dart';
import 'level_intro_sheet.dart';
import 'levels_screen.dart';
import 'profile_screen.dart';

/// Single premium home hub — no bottom nav, no shop/rewards tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AudioCubit>().startMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProgressProvider>(
        builder: (context, progress, _) {
          final p = progress.progress;
          final maxLevel = LevelRepository.instance.totalLevels;
          final level = p.currentLevel.clamp(1, maxLevel);

          return MetaBackdrop(
            child: SafeArea(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      children: [
                        _TopBar(
                          coins: p.coins,
                          gems: p.gems,
                          onProfile: () {
                            context.read<AudioCubit>().playButton();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                        ).animate().fadeIn(duration: 350.ms),
                        const Spacer(flex: 2),
                        const AppLogo(size: 180)
                            .animate()
                            .fadeIn(delay: 60.ms)
                            .scale(begin: const Offset(0.94, 0.94)),
                        const Spacer(flex: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xEE2A1608),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: MetaChrome.gold, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'LEVEL $level',
                            style: GoogleFonts.nunito(
                              color: MetaChrome.gold,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ).animate().fadeIn(delay: 140.ms),
                        const SizedBox(height: 18),
                        GlowPlayButton(
                          onPressed: () =>
                              launchLevel(context, levelId: level),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatPill(
                              asset:
                                  '${PremiumTokens.uiRoot}/meta_star_badge.png',
                              fallback: Icons.star_rounded,
                              label: '${p.totalStars} Stars',
                            ),
                            const SizedBox(width: 10),
                            _StatPill(
                              fallback: Icons.emoji_events_rounded,
                              label: '${_clears(p)} Clears',
                            ),
                          ],
                        ).animate().fadeIn(delay: 200.ms),
                        const Spacer(flex: 2),
                        Row(
                          children: [
                            Expanded(
                              child: _HubTile(
                                icon: Icons.grid_view_rounded,
                                label: 'Levels',
                                subtitle: 'Pick a stage',
                                accent: MetaChrome.gold,
                                onTap: () {
                                  context.read<AudioCubit>().playButton();
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const LevelsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _HubTile(
                                icon: Icons.headphones_rounded,
                                label: 'ASMR',
                                subtitle: 'Calm & sort',
                                accent: const Color(0xFFD4A84B),
                                onTap: () {
                                  context.read<AudioCubit>().playButton();
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const AsmrModeScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 240.ms)
                            .slideY(begin: 0.08),
                        const SizedBox(height: 8),
                        const AdBannerWidget(placement: 'home'),
                      ],
                    ),
                  ),
                  const Positioned(
                    right: 12,
                    bottom: 70,
                    child: GiftBoxFab(pool: GiftLootPool.meta),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static int _clears(PlayerProgress p) =>
      p.levels.values.fold<int>(0, (n, l) => n + l.playCount);
}

class _TopBar extends StatelessWidget {
  final int coins;
  final int gems;
  final VoidCallback onProfile;

  const _TopBar({
    required this.coins,
    required this.gems,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onProfile();
          },
          child: MetaWoodCard(
            padding: const EdgeInsets.all(10),
            child: const Icon(
              Icons.person_rounded,
              color: MetaChrome.gold,
              size: 22,
            ),
          ),
        ),
        const Spacer(),
        CurrencyHud(coins: coins, gems: gems, compact: true),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData fallback;
  final String label;
  final String? asset;

  const _StatPill({
    required this.fallback,
    required this.label,
    this.asset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xEE2A1608),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MetaChrome.brass.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (asset != null)
            Image.asset(
              asset!,
              width: 18,
              height: 18,
              errorBuilder: (context, error, stack) =>
                  Icon(fallback, size: 18, color: MetaChrome.gold),
            )
          else
            Icon(fallback, size: 18, color: MetaChrome.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: MetaChrome.cream,
            ),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _HubTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A2E16),
              Color(0xFF2A1608),
              Color(0xFF1A0E06),
            ],
          ),
          border: Border.all(color: accent, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -18,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              left: -12,
              bottom: -20,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MetaChrome.cream.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: accent.withValues(alpha: 0.18),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.85),
                        width: 1.4,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: MetaChrome.cream,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: MetaChrome.cream.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
