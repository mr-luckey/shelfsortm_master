import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/theme_room.dart';
import '../../ui/premium/premium_tokens.dart';
import 'emoji_assets.dart';

/// Visual kit for one 100-level chapter on the world map.
class MapChapterStyle {
  final List<Color> gradient;
  final Color pathColor;
  final Color accent;
  final Color headerTint;
  /// Large 3D / emoji art layered behind the path.
  final List<String> decorAssets;
  final String? baseBgAsset;

  const MapChapterStyle({
    required this.gradient,
    required this.pathColor,
    required this.accent,
    required this.headerTint,
    required this.decorAssets,
    this.baseBgAsset,
  });

  static const _roomBg = 'assets/images/rooms/premium_room_bg.png';
  static const _metaBg = '${PremiumTokens.uiRoot}/meta_room_bg.png';
  static const _toys = PremiumTokens.toyRoot;

  static MapChapterStyle forRoom(ThemeRoom room) {
    switch (room.id) {
      case 'activities':
        return MapChapterStyle(
          gradient: const [
            Color(0xFF1B4F8A),
            Color(0xFF2E7D32),
            Color(0xFF81C784),
          ],
          pathColor: const Color(0xFF5D4037),
          accent: const Color(0xFFFFB300),
          headerTint: const Color(0xFF1565C0),
          baseBgAsset: _roomBg,
          decorAssets: [
            '$_toys/basketball.webp',
            '$_toys/football.webp',
            '$_toys/dice.webp',
            '$_toys/star.webp',
            EmojiAssets.paths['trophy']!,
            EmojiAssets.paths['soccerball']!,
          ],
        );
      case 'animals':
        return MapChapterStyle(
          gradient: const [
            Color(0xFF1B5E20),
            Color(0xFF43A047),
            Color(0xFFA5D6A7),
          ],
          pathColor: const Color(0xFF4E342E),
          accent: const Color(0xFFFFCA28),
          headerTint: const Color(0xFF2E7D32),
          baseBgAsset: _roomBg,
          decorAssets: [
            '$_toys/cat.webp',
            '$_toys/panda.webp',
            '$_toys/frog.webp',
            '$_toys/owl.webp',
            '$_toys/penguin.webp',
            '$_toys/rabbit.webp',
          ],
        );
      case 'food':
        return MapChapterStyle(
          gradient: const [
            Color(0xFFBF360C),
            Color(0xFFE65100),
            Color(0xFFFFCC80),
          ],
          pathColor: const Color(0xFF6D4C41),
          accent: const Color(0xFFFFD54F),
          headerTint: const Color(0xFFD84315),
          baseBgAsset: _metaBg,
          decorAssets: [
            '$_toys/burger.webp',
            '$_toys/fries.webp',
            '$_toys/ice_cream.webp',
            '$_toys/apple.webp',
            '$_toys/grapes.webp',
            EmojiAssets.paths['pizza']!,
          ],
        );
      case 'hands':
        return MapChapterStyle(
          gradient: const [
            Color(0xFF6A1B9A),
            Color(0xFF8E24AA),
            Color(0xFFF8BBD0),
          ],
          pathColor: const Color(0xFF5D4037),
          accent: const Color(0xFFFF80AB),
          headerTint: const Color(0xFF7B1FA2),
          baseBgAsset: _metaBg,
          decorAssets: [
            EmojiAssets.paths['wavinghand']!,
            EmojiAssets.paths['thumbsup']!,
            EmojiAssets.paths['hearthands']!,
            EmojiAssets.paths['clappinghands']!,
            EmojiAssets.paths['victoryhand']!,
            '$_toys/heart.webp',
          ],
        );
      case 'objects':
        return MapChapterStyle(
          gradient: const [
            Color(0xFF37474F),
            Color(0xFF546E7A),
            Color(0xFF90A4AE),
          ],
          pathColor: const Color(0xFF3E2723),
          accent: const Color(0xFFFFD54F),
          headerTint: const Color(0xFF455A64),
          baseBgAsset: _roomBg,
          decorAssets: [
            '$_toys/robot.webp',
            '$_toys/sunglasses.webp',
            EmojiAssets.paths['lightbulb']!,
            EmojiAssets.paths['key']!,
            EmojiAssets.paths['gemstone']!,
            EmojiAssets.paths['hammer']!,
          ],
        );
      case 'people':
        return MapChapterStyle(
          gradient: const [
            Color(0xFF4A148C),
            Color(0xFF7B1FA2),
            Color(0xFFE1BEE7),
          ],
          pathColor: const Color(0xFF5D4037),
          accent: const Color(0xFFFFD54F),
          headerTint: const Color(0xFF6A1B9A),
          baseBgAsset: _metaBg,
          decorAssets: [
            '$_toys/unicorn.webp',
            '$_toys/teddy.webp',
            EmojiAssets.paths['princess']!,
            EmojiAssets.paths['astronaut']!,
            EmojiAssets.paths['ninja']!,
            EmojiAssets.paths['superhero']!,
          ],
        );
      case 'people_activities':
        return MapChapterStyle(
          gradient: const [
            Color(0xFF00695C),
            Color(0xFF00897B),
            Color(0xFF80CBC4),
          ],
          pathColor: const Color(0xFF4E342E),
          accent: const Color(0xFFFFEE58),
          headerTint: const Color(0xFF00796B),
          baseBgAsset: _roomBg,
          decorAssets: [
            '$_toys/football.webp',
            '$_toys/basketball.webp',
            EmojiAssets.paths['peopleactivitiespersonrunning']!,
            EmojiAssets.paths['peopleactivitiespersonswimming']!,
            EmojiAssets.paths['peopleactivitiespersonsurfing']!,
            '$_toys/star.webp',
          ],
        );
      case 'people_professions':
        return MapChapterStyle(
          gradient: const [
            Color(0xFF0D47A1),
            Color(0xFF1565C0),
            Color(0xFF90CAF9),
          ],
          pathColor: const Color(0xFF5D4037),
          accent: const Color(0xFFFFC107),
          headerTint: const Color(0xFF0D47A1),
          baseBgAsset: _metaBg,
          decorAssets: [
            EmojiAssets.paths['peopleprofessionsfirefighter']!,
            EmojiAssets.paths['peopleprofessionsastronaut']!,
            EmojiAssets.paths['peopleprofessionscook']!,
            EmojiAssets.paths['peopleprofessionsdetective']!,
            EmojiAssets.paths['peopleprofessionshealthworker']!,
            '$_toys/robot.webp',
          ],
        );
      case 'smilies':
        return MapChapterStyle(
          gradient: const [
            Color(0xFFF57F17),
            Color(0xFFFBC02D),
            Color(0xFFFFF59D),
          ],
          pathColor: const Color(0xFF6D4C41),
          accent: const Color(0xFFFF6F00),
          headerTint: const Color(0xFFF9A825),
          baseBgAsset: _metaBg,
          decorAssets: [
            '$_toys/sunglasses.webp',
            '$_toys/heart.webp',
            '$_toys/star.webp',
            EmojiAssets.paths['grinningface']!,
            EmojiAssets.paths['partyingface']!,
            EmojiAssets.paths['starstruck']!,
          ],
        );
      case 'symbols':
        return MapChapterStyle(
          gradient: const [
            Color(0xFF1A237E),
            Color(0xFF3949AB),
            Color(0xFF9FA8DA),
          ],
          pathColor: const Color(0xFF3E2723),
          accent: const Color(0xFFE040FB),
          headerTint: const Color(0xFF283593),
          baseBgAsset: _roomBg,
          decorAssets: [
            '$_toys/star.webp',
            '$_toys/rainbow_rings.webp',
            EmojiAssets.paths['sparkle']!,
            EmojiAssets.paths['glowingstar']!,
            EmojiAssets.paths['diamondwithadot']!,
            EmojiAssets.paths['atomsymbol']!,
          ],
        );
      case 'travel':
        return MapChapterStyle(
          gradient: const [
            Color(0xFF01579B),
            Color(0xFF0288D1),
            Color(0xFF81D4FA),
          ],
          pathColor: const Color(0xFF5D4037),
          accent: const Color(0xFFFFD54F),
          headerTint: const Color(0xFF0277BD),
          baseBgAsset: _roomBg,
          decorAssets: [
            '$_toys/rocket.webp',
            '$_toys/car.webp',
            EmojiAssets.paths['airplane']!,
            EmojiAssets.paths['sunrise']!,
            EmojiAssets.paths['mountfuji']!,
            EmojiAssets.paths['beachwithumbrella']!,
          ],
        );
      default:
        return MapChapterStyle(
          gradient: const [
            Color(0xFF1A2F5A),
            Color(0xFF2E5A8A),
            Color(0xFF81C784),
          ],
          pathColor: const Color(0xFF8D6E63),
          accent: const Color(0xFFFFD54F),
          headerTint: const Color(0xFF1A2F5A),
          baseBgAsset: _metaBg,
          decorAssets: [
            '$_toys/star.webp',
            '$_toys/rocket.webp',
          ],
        );
    }
  }
}

/// Full-bleed chapter backdrop with tinted room art + floating 3D décor.
class ChapterMapBackdrop extends StatelessWidget {
  final ThemeRoom theme;
  final Widget child;

  const ChapterMapBackdrop({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final style = MapChapterStyle.forRoom(theme);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: style.gradient,
                ),
              ),
            ),
          ),
          if (style.baseBgAsset != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.38,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    style.headerTint.withValues(alpha: 0.55),
                    BlendMode.modulate,
                  ),
                  child: Image.asset(
                    style.baseBgAsset!,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: _ChapterDecorLayer(assets: style.decorAssets),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ChapterDecorLayer extends StatelessWidget {
  final List<String> assets;

  const _ChapterDecorLayer({required this.assets});

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        if (h <= 0 || w <= 0) return const SizedBox.shrink();

        // Spread décor along the full chapter height.
        const slots = <(double xFrac, double yFrac, double size, double opacity)>[
          (0.02, 0.04, 78, 0.22),
          (0.74, 0.08, 92, 0.18),
          (0.06, 0.22, 68, 0.16),
          (0.78, 0.30, 80, 0.20),
          (0.04, 0.48, 86, 0.14),
          (0.72, 0.55, 74, 0.17),
          (0.08, 0.72, 70, 0.15),
          (0.76, 0.82, 84, 0.18),
        ];

        return Stack(
          children: [
            for (var i = 0; i < slots.length; i++)
              Positioned(
                left: w * slots[i].$1,
                top: (h * slots[i].$2).clamp(0.0, math.max(0.0, h - slots[i].$3)),
                child: Transform.rotate(
                  angle: (i.isEven ? -1 : 1) * 0.16,
                  child: Opacity(
                    opacity: slots[i].$4,
                    child: Image.asset(
                      assets[i % assets.length],
                      width: slots[i].$3,
                      height: slots[i].$3,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Winding path strip behind level nodes.
class MapPathPainter extends CustomPainter {
  final List<Offset> centers;
  final Color color;

  MapPathPainter({required this.centers, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;

    final path = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (var i = 1; i < centers.length; i++) {
      final prev = centers[i - 1];
      final cur = centers[i];
      final mid = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
      path.quadraticBezierTo(prev.dx, mid.dy, mid.dx, mid.dy);
      path.quadraticBezierTo(cur.dx, mid.dy, cur.dx, cur.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..strokeWidth = 28
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 22
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE8D5B5)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant MapPathPainter old) =>
      old.centers != centers || old.color != color;
}

List<Offset> computeMapCenters({
  required int count,
  required double pathWidth,
  required double startLevel,
  double nodeSize = 58,
  double rowGap = 78,
}) {
  final centers = <Offset>[];
  for (var i = 0; i < count; i++) {
    final t = i / math.max(1, count - 1);
    final x = pathWidth / 2 +
        math.sin(t * math.pi * 2.2 + (startLevel / 100) * 0.7) *
            (pathWidth * 0.30);
    final y = i * rowGap + nodeSize / 2;
    centers.add(Offset(x, y));
  }
  return centers;
}
