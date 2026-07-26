import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../data/level_repository.dart';
import '../../models/theme_room.dart';
import 'gameplay_screen.dart';

Future<void> showLevelIntro(
  BuildContext context, {
  required int levelId,
  bool daily = false,
}) async {
  final level = daily
      ? LevelRepository.instance.dailyChallenge(DateTime.now())
      : LevelRepository.instance.getLevel(levelId);
  final theme = daily ? ThemeRoom.all.first : level.theme;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              daily ? 'Daily Challenge' : 'Level ${level.levelId}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '${theme.emoji} ${theme.name}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _Badge(level.difficultyEnum.label, AppColors.primary),
                _Badge('${level.timeLimit}s', const Color(0xFF29B6F6)),
                _Badge(
                  '${level.initialPlacement.length} goods',
                  AppColors.accent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Move mixed goods between shelves. Group 3 identical items on one shelf to clear them. Use empty BUFFER shelves as working space!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GameplayScreen(
                            levelId: levelId,
                            daily: daily,
                          ),
                        ),
                      );
                    },
                    child: const Text('Play'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
