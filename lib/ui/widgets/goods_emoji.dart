import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_colors.dart';
import '../../models/item.dart';

/// Chunky emoji goods — stands in for 3D bottles until art pack lands.
class GoodsEmoji extends StatelessWidget {
  final GameItem item;
  final double size;
  final bool lifting;
  final bool dimmed;

  const GoodsEmoji({
    super.key,
    required this.item,
    this.size = 48,
    this.lifting = false,
    this.dimmed = false,
  });

  static String emojiFor(String type) {
    const map = {
      'mug': '☕',
      'cup': '🥤',
      'jar': '🍯',
      'cupcake': '🧁',
      'box': '📦',
      'macaron': '🍪',
      'book': '📚',
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
      'ornament': '🎁',
    };
    return map[type] ?? '✨';
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forItemColor(item.color);
    Widget child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.35)!,
            color,
            Color.lerp(color, Colors.black, 0.12)!,
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: lifting ? 0.55 : 0.35),
            blurRadius: lifting ? 16 : 8,
            offset: Offset(0, lifting ? 10 : 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        emojiFor(item.type),
        style: TextStyle(fontSize: size * 0.5),
      ),
    );

    if (lifting) {
      child = child
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -3, duration: 500.ms);
    }
    if (dimmed) {
      child = Opacity(opacity: 0.25, child: child);
    }
    return child;
  }
}
