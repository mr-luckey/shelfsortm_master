import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_colors.dart';
import '../../models/item.dart';

class ItemWidget extends StatelessWidget {
  final GameItem item;
  final bool isHeld;
  final bool highlighted;
  final bool highContrast;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double size;

  const ItemWidget({
    super.key,
    required this.item,
    this.isHeld = false,
    this.highlighted = false,
    this.highContrast = false,
    this.onTap,
    this.onLongPress,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forItemColor(item.color);
    final pattern = _patternFor(item.type);

    Widget child = GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: size,
        height: size,
        transform: isHeld
            ? Matrix4.translationValues(0, -8, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, 0.25)!,
              color,
              Color.lerp(color, Colors.black, 0.15)!,
            ],
          ),
          border: Border.all(
            color: highlighted ? AppColors.secondary : Colors.white.withValues(alpha: 0.55),
            width: highlighted ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isHeld ? 0.55 : 0.35),
              blurRadius: isHeld ? 16 : 8,
              offset: Offset(0, isHeld ? 10 : 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _PatternPainter(pattern, highContrast)),
            ),
            Center(
              child: Text(
                _emojiFor(item.type),
                style: TextStyle(fontSize: size * 0.42),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 3,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isHeld) {
      child = child
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -4, duration: 700.ms, curve: Curves.easeInOut);
    }
    if (highlighted) {
      child = child
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 500.ms);
    }

    return child;
  }

  static String _emojiFor(String type) {
    const map = {
      'mug': '☕',
      'cup': '🥤',
      'jar': '🫙',
      'cupcake': '🧁',
      'box': '📦',
      'macaron': '🍪',
      'book': '📘',
      'candle': '🕯️',
      'globe': '🌍',
      'pot': '🪴',
      'can': '🥫',
      'seed': '🌱',
      'teddy': '🧸',
      'block': '🧱',
      'ball': '⚽',
      'perfume': '🧴',
      'lipstick': '💄',
      'cream': '🫧',
      'controller': '🎮',
      'cartridge': '💾',
      'headset': '🎧',
      'sauce': '🍾',
      'snack': '🍿',
      'vase': '🏺',
      'frame': '🖼️',
      'ribbon': '🎀',
      'bag': '🛍️',
      'ornament': '🎄',
    };
    return map[type] ?? '✨';
  }

  static _Pattern _patternFor(String type) {
    switch (type.hashCode % 3) {
      case 0:
        return _Pattern.dots;
      case 1:
        return _Pattern.stripes;
      default:
        return _Pattern.grid;
    }
  }
}

enum _Pattern { dots, stripes, grid }

class _PatternPainter extends CustomPainter {
  final _Pattern pattern;
  final bool highContrast;

  _PatternPainter(this.pattern, this.highContrast);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: highContrast ? 0.45 : 0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    switch (pattern) {
      case _Pattern.dots:
        for (var x = 8.0; x < size.width; x += 10) {
          for (var y = 8.0; y < size.height; y += 10) {
            canvas.drawCircle(Offset(x, y), 1.4, paint..style = PaintingStyle.fill);
          }
        }
      case _Pattern.stripes:
        for (var x = 0.0; x < size.width + size.height; x += 8) {
          canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), paint);
        }
      case _Pattern.grid:
        for (var x = 6.0; x < size.width; x += 8) {
          canvas.drawLine(Offset(x, 4), Offset(x, size.height - 4), paint);
        }
        for (var y = 6.0; y < size.height; y += 8) {
          canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), paint);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) =>
      oldDelegate.pattern != pattern || oldDelegate.highContrast != highContrast;
}
