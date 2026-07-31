import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../app/theme/goods_sort_theme.dart';
import '../../models/player_progress.dart';
import '../../models/theme_room.dart';
import '../../providers/progress_provider.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/goods_emoji.dart';
import '../widgets/map_background.dart';
import 'level_intro_sheet.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  final _scroll = ScrollController();
  bool _scrolledToCurrent = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToCurrent(int currentLevel) {
    if (_scrolledToCurrent) return;
    _scrolledToCurrent = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      // Rough offset: each level ~78px within its zone + zone headers
      final per = ThemeRoom.levelsPerFlavor;
      final zoneIndex = ((currentLevel - 1) / per).floor();
      final indexInZone = (currentLevel - 1) % per;
      final offset = zoneIndex * 220.0 + indexInZone * 78.0;
      _scroll.animateTo(
        offset.clamp(0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progress, _) {
        final p = progress.progress;
        _scrollToCurrent(p.currentLevel);

        return Stack(
          fit: StackFit.expand,
          children: [
            const MapBackground(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              EmojiImage(type: 'trophy', size: 20),
                              SizedBox(width: 8),
                              Text(
                                'World Tour',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB300),
                                size: 18,
                              ),
                              Text(
                                ' ${p.totalStars}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!p.removeAds)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      child: Center(child: AdBannerWidget()),
                    ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 28),
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
          ],
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
    launchLevel(context, levelId: id);
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
    const nodeSize = 58.0;
    const rowGap = 78.0;

    final centers = computeMapCenters(
      count: count,
      pathWidth: pathWidth,
      startLevel: theme.startLevel.toDouble(),
      nodeSize: nodeSize,
      rowGap: rowGap,
    );

    final nodes = <Widget>[
      Positioned.fill(
        child: CustomPaint(
          painter: MapPathPainter(
            centers: centers,
            color: GoodsSortTheme.pathBrown,
          ),
        ),
      ),
    ];

    for (var i = 0; i < count; i++) {
      final levelId = theme.startLevel + i;
      final c = centers[i];
      nodes.add(
        Positioned(
          left: c.dx - nodeSize / 2,
          top: c.dy - nodeSize / 2,
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
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  GoodsSortTheme.playGreen.withValues(alpha: 0.92),
                  GoodsSortTheme.playGreenDark.withValues(alpha: 0.92),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: GoodsSortTheme.playGreen.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                EmojiImage(type: theme.iconType, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Levels ${theme.startLevel}–${theme.endLevel}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.flag_rounded, color: Colors.white70),
              ],
            ),
          ),
        ),
        Center(
          child: SizedBox(
            height: height,
            width: pathWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: nodes,
            ),
          ),
        ),
      ],
    );
  }
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
    final per = ThemeRoom.levelsPerFlavor;
    final isBoss = levelId % per == 0;
    final isRest = (levelId - 1) % per == 0;

    Color face;
    Color ring;
    if (!unlocked) {
      face = const Color(0xFFBDBDBD);
      ring = const Color(0xFF9E9E9E);
    } else if (isCurrent) {
      face = const Color(0xFFFFB300);
      ring = const Color(0xFFFF8F00);
    } else if (isBoss) {
      face = const Color(0xFFE53935);
      ring = const Color(0xFFB71C1C);
    } else if (isRest) {
      face = GoodsSortTheme.playGreenLight;
      ring = GoodsSortTheme.playGreen;
    } else if (stars >= 3) {
      face = const Color(0xFFFFD54F);
      ring = const Color(0xFFFFA000);
    } else {
      face = Colors.white;
      ring = GoodsSortTheme.playGreen;
    }

    Widget node = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: face,
          border: Border.all(color: ring, width: isCurrent ? 4 : 3),
          boxShadow: [
            BoxShadow(
              color: ring.withValues(alpha: 0.45),
              blurRadius: isCurrent ? 14 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              Icon(Icons.lock_rounded, color: ring.withValues(alpha: 0.7), size: 22)
            else if (isBoss)
              const EmojiImage(type: '1stplacemedal', size: 22)
            else ...[
              Text(
                '$levelId',
                style: TextStyle(
                  color: unlocked && face == Colors.white
                      ? GoodsSortTheme.playGreenDark
                      : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              if (stars > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    stars.clamp(0, 3),
                    (_) => Icon(
                      Icons.star,
                      size: 8,
                      color: ring.withValues(alpha: 0.9),
                    ),
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
            end: const Offset(1.12, 1.12),
            duration: 900.ms,
          );
    }

    return node;
  }
}
