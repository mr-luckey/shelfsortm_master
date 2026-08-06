import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../bloc/audio_cubit.dart';
import '../../models/player_progress.dart';
import '../../models/theme_room.dart';
import '../../providers/progress_provider.dart';
import '../meta/meta_chrome.dart';
import '../premium/premium_tokens.dart';
import '../widgets/goods_emoji.dart';
import '../widgets/map_background.dart';
import 'level_intro_sheet.dart';

/// Tracks one-shot auto-scroll to the current level (no setState).
class _MapScrollCubit extends Cubit<bool> {
  _MapScrollCubit() : super(false);

  void markDone() {
    if (!state) emit(true);
  }
}

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  final _scroll = ScrollController();
  late final _MapScrollCubit _scrollCubit;

  @override
  void initState() {
    super.initState();
    _scrollCubit = _MapScrollCubit();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _scrollCubit.close();
    super.dispose();
  }

  void _scrollToCurrent(int currentLevel) {
    if (_scrollCubit.state) return;
    _scrollCubit.markDone();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final per = ThemeRoom.levelsPerFlavor;
      final zoneIndex = ((currentLevel - 1) / per).floor();
      final indexInZone = (currentLevel - 1) % per;
      final offset = zoneIndex * 240.0 + indexInZone * 78.0;
      _scroll.animateTo(
        offset.clamp(0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _scrollCubit,
      child: Consumer<ProgressProvider>(
        builder: (context, progress, _) {
          final p = progress.progress;
          _scrollToCurrent(p.currentLevel);

          return Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFF0E1A2E)),
                Image.asset(
                  MetaChrome.bgAsset,
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.45),
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _MapHeader(
                        totalStars: p.totalStars,
                        onBack: () {
                          context.read<AudioCubit>().playButton();
                          Navigator.of(context).maybePop();
                        },
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
                          itemCount: ThemeRoom.all.length,
                          itemBuilder: (context, section) {
                            final theme = ThemeRoom.all[section];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ZoneSection(
                                theme: theme,
                                progress: p,
                                onLevelTap: (id) => _openLevel(context, p, id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openLevel(BuildContext context, PlayerProgress p, int id) {
    final lp = p.levelOf(id);
    if (!lp.unlocked) {
      context.read<AudioCubit>().playInvalid();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete previous levels to unlock!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<AudioCubit>().playButton();
    launchLevel(context, levelId: id);
  }
}

class _MapHeader extends StatelessWidget {
  final int totalStars;
  final VoidCallback onBack;

  const _MapHeader({required this.totalStars, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: MetaChrome.cream,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xEE3A2412), Color(0xEE5A3418)],
                ),
                border: Border.all(color: MetaChrome.gold, width: 1.5),
              ),
              child: Row(
                children: [
                  const EmojiImage(type: 'worldmap', size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'World Tour',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: MetaChrome.gold,
                      ),
                    ),
                  ),
                  Image.asset(
                    MetaChrome.starBadgeAsset,
                    width: 22,
                    height: 22,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.star_rounded,
                      color: MetaChrome.gold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$totalStars',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      color: MetaChrome.cream,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
    final pathWidth = MediaQuery.sizeOf(context).width - 48;
    const nodeSize = 58.0;
    const rowGap = 78.0;
    final style = MapChapterStyle.forRoom(theme);

    final centers = computeMapCenters(
      count: count,
      pathWidth: pathWidth,
      startLevel: theme.startLevel.toDouble(),
      nodeSize: nodeSize,
      rowGap: rowGap,
    );

    final height = count * rowGap + nodeSize;
    final cleared = _clearedInZone(progress, theme);
    final unlockedHere = progress.currentLevel >= theme.startLevel;

    return ChapterMapBackdrop(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChapterBanner(
            theme: theme,
            style: style,
            cleared: cleared,
            total: count,
            locked: !unlockedHere && theme.startLevel > 1,
          ),
          SizedBox(
            height: height,
            width: double.infinity,
            child: Center(
              child: SizedBox(
                height: height,
                width: pathWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: MapPathPainter(
                          centers: centers,
                          color: style.pathColor,
                        ),
                      ),
                    ),
                    for (var i = 0; i < count; i++)
                      Positioned(
                        left: centers[i].dx - nodeSize / 2,
                        top: centers[i].dy - nodeSize / 2,
                        child: _LevelNode(
                          levelId: theme.startLevel + i,
                          progress: progress.levelOf(theme.startLevel + i),
                          isCurrent:
                              theme.startLevel + i == progress.currentLevel,
                          accent: style.accent,
                          onTap: () => onLevelTap(theme.startLevel + i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static int _clearedInZone(PlayerProgress p, ThemeRoom theme) {
    var n = 0;
    for (var id = theme.startLevel; id <= theme.endLevel; id++) {
      if (p.levelOf(id).bestStars > 0) n++;
    }
    return n;
  }
}

class _ChapterBanner extends StatelessWidget {
  final ThemeRoom theme;
  final MapChapterStyle style;
  final int cleared;
  final int total;
  final bool locked;

  const _ChapterBanner({
    required this.theme,
    required this.style,
    required this.cleared,
    required this.total,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withValues(alpha: 0.42),
          border: Border.all(
            color: style.accent.withValues(alpha: 0.85),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.headerTint.withValues(alpha: 0.85),
                border: Border.all(color: style.accent, width: 2),
              ),
              child: Center(
                child: EmojiImage(type: theme.iconType, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.name,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: MetaChrome.cream,
                    ),
                  ),
                  Text(
                    'Levels ${theme.startLevel}–${theme.endLevel}',
                    style: GoogleFonts.nunito(
                      color: MetaChrome.cream.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (locked)
              Icon(
                Icons.lock_rounded,
                color: MetaChrome.cream.withValues(alpha: 0.7),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$cleared/$total',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      color: style.accent,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'cleared',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      color: MetaChrome.cream.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  final int levelId;
  final LevelProgress progress;
  final bool isCurrent;
  final Color accent;
  final VoidCallback onTap;

  const _LevelNode({
    required this.levelId,
    required this.progress,
    required this.isCurrent,
    required this.accent,
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
      face = const Color(0xFF6B7280);
      ring = const Color(0xFF4B5563);
    } else if (isCurrent) {
      face = accent;
      ring = Colors.white;
    } else if (isBoss) {
      face = const Color(0xFFE53935);
      ring = const Color(0xFFFFCDD2);
    } else if (isRest) {
      face = const Color(0xFF43A047);
      ring = const Color(0xFFC8E6C9);
    } else if (stars >= 3) {
      face = const Color(0xFFFFB300);
      ring = const Color(0xFFFFECB3);
    } else if (stars > 0) {
      face = const Color(0xFF1E88E5);
      ring = const Color(0xFFBBDEFB);
    } else {
      face = const Color(0xFFF5F5F5);
      ring = PremiumTokens.woodDark;
    }

    Widget inner;
    if (!unlocked) {
      inner = Icon(
        Icons.lock_rounded,
        color: Colors.white.withValues(alpha: 0.85),
        size: 22,
      );
    } else if (isBoss) {
      inner = const EmojiImage(type: '1stplacemedal', size: 26);
    } else {
      inner = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$levelId',
            style: TextStyle(
              color: face == const Color(0xFFF5F5F5)
                  ? PremiumTokens.woodDark
                  : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              height: 1,
            ),
          ),
          if (stars > 0) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  Icons.star_rounded,
                  size: 9,
                  color: i < stars
                      ? const Color(0xFFFFF59D)
                      : Colors.black.withValues(alpha: 0.2),
                ),
              ),
            ),
          ],
        ],
      );
    }

    Widget node = GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isCurrent && unlocked)
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.28),
              ),
            ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(face, Colors.white, 0.22)!,
                  face,
                  Color.lerp(face, Colors.black, 0.18)!,
                ],
              ),
              border: Border.all(color: ring, width: isCurrent ? 3.5 : 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: isCurrent ? 12 : 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: inner,
          ),
        ],
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
