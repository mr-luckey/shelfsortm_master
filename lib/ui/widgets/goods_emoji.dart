import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/goods_sort_theme.dart';
import '../../models/item.dart';
import 'emoji_assets.dart';

/// High-contrast emoji tile — distinct ring + white core (avoids "blend together").
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

  static String _typeGlyph(String type) {
    const glyphs = ['B', '□', '●', '◆'];
    return glyphs[type.hashCode.abs() % glyphs.length];
  }

  @override
  Widget build(BuildContext context) {
    final ring = GoodsSortTheme.itemRing(item.color);
    final plateFill = GoodsSortTheme.itemPlateFill(item.color);
    final emojiSize = size * (onShelf ? 0.78 : 0.92);
    final tile = size * (onShelf ? 0.88 : 1.05);
    final showBadge = !onShelf;

    Widget body = SizedBox(
      width: tile,
      height: tile,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: tile * 0.92,
            height: tile * 0.92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: ring, width: onShelf ? 2.5.w : 3.6.w),
              boxShadow: [
                BoxShadow(
                  color: ring.withValues(alpha: 0.35),
                  blurRadius: lifting ? 10.r : 4.r,
                  offset: Offset(0, lifting ? 5.h : 2.h),
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: plateFill,
              ),
              child: Center(
                child: EmojiImage(type: item.type, size: emojiSize),
              ),
            ),
          ),
          if (showBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: tile * 0.24,
                height: tile * 0.24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ring,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2.w),
                ),
                child: Text(
                  _typeGlyph(item.type),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: tile * 0.12,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (lifting && !onShelf) {
      body = body
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -8.h, duration: 360.ms, curve: Curves.easeOut);
    }
    if (celebrating) {
      body = body
          .animate()
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.18, 1.18),
            duration: 200.ms,
          )
          .then()
          .fadeOut(duration: 240.ms);
    }
    if (dimmed) {
      body = Opacity(opacity: 0.28, child: body);
    }
    return body;
  }
}

/// Bare emoji artwork, no tile behind it.
class EmojiImage extends StatelessWidget {
  final String type;
  final double size;

  const EmojiImage({super.key, required this.type, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(EmojiAssets.pathFor(type), width: size, height: size);
  }
}

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
          return EmojiImage(type: 'sparkles', size: 14.w + (i % 2) * 6.w)
              .animate()
              .move(
                begin: Offset.zero,
                end: Offset((i - 2) * 18.w, -20.h - i * 6.h),
                duration: 500.ms,
                curve: Curves.easeOut,
              )
              .fadeOut(duration: 500.ms);
        }),
      ),
    );
  }
}

class PreviewEmoji extends StatelessWidget {
  final String type;
  final String color;
  final double size;

  const PreviewEmoji({
    super.key,
    required this.type,
    required this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GoodsEmoji(
      item: GameItem(type: type, color: color, id: '${type}_${color}_preview'),
      size: size,
      onShelf: true,
    );
  }
}
