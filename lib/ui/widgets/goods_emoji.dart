import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_colors.dart';
import '../../models/item.dart';

/// Large emoji on a product plate — Goods Sort™ style (no image assets).
class GoodsEmoji extends StatelessWidget {
  final GameItem item;
  final double size;
  final bool lifting;
  final bool dimmed;
  final bool onShelf;
  final bool celebrating;

  const GoodsEmoji({
    super.key,
    required this.item,
    this.size = 48,
    this.lifting = false,
    this.dimmed = false,
    this.onShelf = false,
    this.celebrating = false,
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
      'apple': '🍎',
      'banana': '🍌',
      'grape': '🍇',
      'bread': '🍞',
      'pizza': '🍕',
      'burger': '🍔',
      'fries': '🍟',
      'donut': '🍩',
      'icecream': '🍦',
      'water': '💧',
      'milk': '🥛',
      'tea': '🍵',
      'wine': '🍷',
      'beer': '🍺',
      'plant': '🌿',
      'flower': '🌸',
      'soap': '🧼',
      'tooth': '🪥',
    };
    return map[type] ?? '✨';
  }

  @override
  Widget build(BuildContext context) {
    final emojiSize = onShelf ? size * 0.72 : size * 0.82;
    final plate = size * (onShelf ? 0.92 : 1.0);

    Widget body = SizedBox(
      width: plate,
      height: plate,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Contact shadow on shelf
          if (onShelf)
            Positioned(
              bottom: 2,
              left: plate * 0.12,
              right: plate * 0.12,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: Colors.black.withValues(alpha: 0.22),
                ),
              ),
            ),
          // White product plate (Goods Sort item pedestal)
          Container(
            width: plate * 0.88,
            height: plate * 0.88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white,
                  Color.lerp(
                    AppColors.forItemColor(item.color),
                    Colors.white,
                    0.75,
                  )!,
                ],
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: lifting ? 0.35 : 0.18),
                  blurRadius: lifting ? 10 : 4,
                  offset: Offset(0, lifting ? 8 : 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                emojiFor(item.type),
                style: TextStyle(fontSize: emojiSize, height: 1),
              ),
            ),
          ),
        ],
      ),
    );

    if (lifting) {
      body = body
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -8, duration: 380.ms, curve: Curves.easeOut);
    }
    if (celebrating) {
      body = body
          .animate()
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.2, 1.2),
            duration: 200.ms,
          )
          .then()
          .fadeOut(duration: 250.ms);
    }
    if (dimmed) {
      body = Opacity(opacity: 0.25, child: body);
    }
    return body;
  }
}

/// Sparkle burst when a shelf compartment closes.
class MatchBurst extends StatelessWidget {
  final Color color;
  final double size;

  const MatchBurst({super.key, required this.color, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(5, (i) {
          return Text('✨', style: TextStyle(fontSize: 14 + (i % 2) * 6))
              .animate()
              .move(
                begin: Offset.zero,
                end: Offset((i - 2) * 18.0, -20 - i * 6.0),
                duration: 500.ms,
                curve: Curves.easeOut,
              )
              .fadeOut(duration: 500.ms);
        }),
      ),
    );
  }
}
