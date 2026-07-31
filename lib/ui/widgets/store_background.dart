import 'package:flutter/material.dart';

import 'goods_emoji.dart';

/// Supermarket aisle backdrop — depth shelves + warm lighting (Goods Sort vibe).
class StoreBackground extends StatelessWidget {
  final List<Color> colors;
  final String moodType;

  const StoreBackground({
    super.key,
    required this.colors,
    this.moodType = 'hamburger',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors.length >= 2
                  ? colors
                  : const [
                      Color(0xFFE8F4FD),
                      Color(0xFFFFF8EE),
                      Color(0xFFF5EDE0),
                    ],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _FloorPainter()),
        ),
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          height: 140,
          child: Opacity(
            opacity: 0.35,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) {
                return Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateX(-0.45),
                  child: _BackShelf(tone: i),
                );
              }),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 48,
          right: 20,
          child: Opacity(
            opacity: 0.12,
            child: EmojiImage(type: moodType, size: 64),
          ),
        ),
      ],
    );
  }
}

class _BackShelf extends StatelessWidget {
  final int tone;
  const _BackShelf({required this.tone});

  @override
  Widget build(BuildContext context) {
    final wood = Color.lerp(
      const Color(0xFF8D6E63),
      const Color(0xFF6D4C41),
      tone / 4,
    )!;
    return Container(
      width: 72,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [wood.withValues(alpha: 0.9), wood.withValues(alpha: 0.55)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: EmojiImage(
              type: const [
                'hamburger',
                'catface',
                'grinningface',
                'airplane',
              ][(tone + i) % 4],
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.72;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.2;

    for (var i = 0; i < 8; i++) {
      final y = horizon + (size.height - horizon) * (i / 8);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var i = -4; i <= 4; i++) {
      canvas.drawLine(
        Offset(size.width / 2, horizon),
        Offset(size.width / 2 + i * 48, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
