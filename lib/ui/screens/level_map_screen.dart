import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../models/theme_room.dart';
import '../../providers/progress_provider.dart';
import 'level_intro_sheet.dart';

class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progress, _) {
        final p = progress.progress;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.background, Color(0xFFFFE8D6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Store Blueprint',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                if (!p.removeAds)
                  Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Banner Ad Placeholder',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: ThemeRoom.all.length,
                    itemBuilder: (context, section) {
                      final theme = ThemeRoom.all[section];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              '${theme.emoji} ${theme.name} (${theme.startLevel}–${theme.endLevel})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (var id = theme.startLevel;
                                  id <= theme.endLevel;
                                  id++)
                                _LevelNode(
                                  levelId: id,
                                  progress: p.levelOf(id),
                                  isCurrent: id == p.currentLevel,
                                  onTap: () {
                                    final lp = p.levelOf(id);
                                    if (!lp.unlocked) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Keep playing to unlock!',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }
                                    showLevelIntro(context, levelId: id);
                                  },
                                ),
                            ],
                          ),
                        ],
                      );
                    },
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

class _LevelNode extends StatelessWidget {
  final int levelId;
  final dynamic progress;
  final bool isCurrent;
  final VoidCallback onTap;

  const _LevelNode({
    required this.levelId,
    required this.progress,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.unlocked as bool;
    final stars = progress.bestStars as int;
    Color bg;
    if (!unlocked) {
      bg = Colors.grey.shade300;
    } else if (stars >= 3) {
      bg = const Color(0xFFFFD700);
    } else if (stars == 2) {
      bg = const Color(0xFFC0C0C0);
    } else if (stars == 1) {
      bg = const Color(0xFFCD7F32);
    } else {
      bg = AppColors.primary;
    }

    Widget node = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [bg, Color.lerp(bg, Colors.black, 0.15)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(Icons.lock_rounded, color: Colors.white70, size: 22)
            else ...[
              Text(
                '$levelId',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              if (stars > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    stars,
                    (_) => const Icon(Icons.star, size: 10, color: Colors.white),
                  ),
                ),
            ],
          ],
        ),
      ),
    );

    if (isCurrent && unlocked) {
      node = node
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 900.ms,
          );
    }

    return node;
  }
}
