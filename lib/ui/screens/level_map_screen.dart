import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../models/player_progress.dart';
import '../../models/theme_room.dart';
import '../../providers/progress_provider.dart';
import '../widgets/ad_banner_widget.dart';
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Store Blueprint',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${p.totalStars} ★',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!p.removeAds)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Center(child: AdBannerWidget()),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                    itemCount: ThemeRoom.all.length,
                    itemBuilder: (context, section) {
                      final theme = ThemeRoom.all[section];
                      return _ZoneSection(
                        theme: theme,
                        progress: p,
                        onLevelTap: (id) => _openLevel(context, p, id),
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

  void _openLevel(BuildContext context, PlayerProgress p, int id) {
    final lp = p.levelOf(id);
    if (!lp.unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete previous levels to unlock!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showLevelIntro(context, levelId: id);
  }
}

class _ZoneSection extends StatelessWidget {
  final ThemeRoom theme;
  final PlayerProgress progress;
  final void Function(int levelId) onLevelTap;

  const _ZoneSection({
    required this.theme,
    required this.progress,
    required this.onLevelTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = theme.endLevel - theme.startLevel + 1;
    final pathWidth = MediaQuery.sizeOf(context).width - 32;
    const nodeSize = 56.0;
    const rowGap = 76.0;

    final nodes = <Widget>[];
    Offset? prevCenter;

    for (var i = 0; i < count; i++) {
      final levelId = theme.startLevel + i;
      final t = i / math.max(1, count - 1);
      final x = pathWidth / 2 +
          math.sin(t * math.pi * 2.4 + sectionPhase(theme.startLevel)) *
              (pathWidth * 0.32);
      final y = i * rowGap + nodeSize / 2;
      final center = Offset(x, y);

      if (prevCenter != null) {
        nodes.add(
          Positioned.fill(
            child: CustomPaint(
              painter: _PathConnector(
                from: prevCenter,
                to: center,
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
          ),
        );
      }
      prevCenter = center;

      nodes.add(
        Positioned(
          left: x - nodeSize / 2,
          top: y - nodeSize / 2,
          child: _LevelNode(
            levelId: levelId,
            progress: progress.levelOf(levelId),
            isCurrent: levelId == progress.currentLevel,
            onTap: () => onLevelTap(levelId),
          ),
        ),
      );
    }

    final height = count * rowGap + nodeSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(theme.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Levels ${theme.startLevel}–${theme.endLevel}',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: height,
          width: pathWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: nodes,
          ),
        ),
      ],
    );
  }

  double sectionPhase(int startLevel) => (startLevel / 25) * 0.8;
}

class _PathConnector extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;

  _PathConnector({
    required this.from,
    required this.to,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(mid.dx, from.dy, mid.dx, mid.dy)
      ..quadraticBezierTo(mid.dx, to.dy, to.dx, to.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathConnector old) =>
      old.from != from || old.to != to || old.color != color;
}

class _LevelNode extends StatelessWidget {
  final int levelId;
  final LevelProgress progress;
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
    final unlocked = progress.unlocked;
    final stars = progress.bestStars;
    final isBoss = levelId % 25 == 0;
    final isRest = (levelId - 1) % 25 == 0;

    Color bg;
    if (!unlocked) {
      bg = Colors.grey.shade400;
    } else if (stars >= 3) {
      bg = const Color(0xFFFFD700);
    } else if (stars == 2) {
      bg = const Color(0xFFC0C0C0);
    } else if (stars == 1) {
      bg = const Color(0xFFCD7F32);
    } else if (isBoss) {
      bg = const Color(0xFFE53935);
    } else if (isRest) {
      bg = const Color(0xFF66BB6A);
    } else {
      bg = AppColors.primary;
    }

    Widget node = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [bg, Color.lerp(bg, Colors.black, 0.18)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isCurrent ? Colors.amber : Colors.white,
            width: isCurrent ? 3.5 : 2.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(Icons.lock_rounded, color: Colors.white70, size: 20)
            else if (isBoss)
              const Icon(Icons.whatshot, color: Colors.white, size: 22)
            else ...[
              Text(
                '$levelId',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              if (stars > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    stars.clamp(0, 3),
                    (_) =>
                        const Icon(Icons.star, size: 9, color: Colors.white),
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
            end: const Offset(1.1, 1.1),
            duration: 900.ms,
          );
    }

    return node;
  }
}
