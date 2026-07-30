import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/item.dart';
import 'goods_emoji.dart';

/// Conveyor belt row — Goods Puzzle style incoming goods lane.
class ConveyorBeltRow extends StatelessWidget {
  final List<GameItem?> belt;
  final ShelfLookAccent accent;
  final void Function(int index)? onPick;

  const ConveyorBeltRow({
    super.key,
    required this.belt,
    this.accent = const ShelfLookAccent(),
    this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    if (belt.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF78909C).withValues(alpha: 0.85),
            const Color(0xFF546E7A).withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: Colors.white54, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.linear_scale, color: accent.color, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(belt.length, (i) {
                  final item = belt[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: item != null ? () => onPick?.call(i) : null,
                      child: Container(
                        width: 52,
                        height: 58,
                        alignment: Alignment.bottomCenter,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black26,
                          border: Border.all(
                            color: item != null
                                ? accent.color.withValues(alpha: 0.6)
                                : Colors.white24,
                          ),
                        ),
                        child: item == null
                            ? null
                            : GoodsEmoji(
                                item: item,
                                size: 40,
                                onShelf: true,
                              ),
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(
                        duration: 1800.ms,
                        color: Colors.white.withValues(alpha: 0.08),
                      );
                }),
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 16),
        ],
      ),
    );
  }
}

class ShelfLookAccent {
  final Color color;
  const ShelfLookAccent({this.color = const Color(0xFFFFD700)});
}

/// Ping-pong moving bottom tray (extra holding shelf).
class MovingTrayBar extends StatelessWidget {
  final double position; // 0..1
  final int slotCount;
  final Color accent;

  const MovingTrayBar({
    super.key,
    required this.position,
    this.slotCount = 4,
    this.accent = const Color(0xFF4CAF50),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trayW = constraints.maxWidth * 0.55;
        final left = (constraints.maxWidth - trayW) * position;
        return SizedBox(
          height: 56,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withValues(alpha: 0.15),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 80),
                curve: Curves.linear,
                left: left.clamp(8.0, constraints.maxWidth - trayW - 8),
                top: 4,
                width: trayW,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.85),
                        accent.withValues(alpha: 0.65),
                      ],
                    ),
                    border: Border.all(color: Colors.white70, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      slotCount,
                      (_) => Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white54),
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Vertical divider on a shelf (moving divider mechanic).
class ShelfDividerBar extends StatelessWidget {
  final int slotIndex;
  final int slotCount;
  final Color color;

  const ShelfDividerBar({
    super.key,
    required this.slotIndex,
    required this.slotCount,
    this.color = const Color(0xFFFF6B35),
  });

  @override
  Widget build(BuildContext context) {
    if (slotCount <= 1) return const SizedBox.shrink();
    final frac = (slotIndex + 0.5) / slotCount;
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, c) {
            return Stack(
              children: [
                Positioned(
                  left: c.maxWidth * frac - 2,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.9),
                          color.withValues(alpha: 0.4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Goods Puzzle style top progress — sets remaining.
class SetsProgressBar extends StatelessWidget {
  final int setsLeft;
  final int totalSets;
  final Color accent;

  const SetsProgressBar({
    super.key,
    required this.setsLeft,
    required this.totalSets,
    this.accent = const Color(0xFF4CAF50),
  });

  @override
  Widget build(BuildContext context) {
    final done = totalSets <= 0 ? 0.0 : 1 - (setsLeft / totalSets).clamp(0, 1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sets left: $setsLeft',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Color(0xFF5D4037),
                ),
              ),
              Text(
                '${(done * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: done.toDouble(),
              minHeight: 8,
              backgroundColor: Colors.brown.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}
