import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_colors.dart';
import '../../engine/match_engine.dart';
import '../../models/item.dart';
import '../../models/shelf.dart';
import 'goods_emoji.dart';

class DragData {
  final BoardPos from;
  final GameItem item;
  const DragData({required this.from, required this.item});
}

/// Sort Challenge cabinet shelf — 3 slots, wooden plank, buffer highlight.
class CabinetShelf extends StatelessWidget {
  final Shelf shelf;
  final int shelfIndex;
  final BoardPos? selected;
  final bool celebrating;
  final bool isBuffer;
  final void Function(BoardPos pos) onTap;
  final void Function(BoardPos from, BoardPos to) onMove;

  const CabinetShelf({
    super.key,
    required this.shelf,
    required this.shelfIndex,
    required this.onTap,
    required this.onMove,
    this.selected,
    this.celebrating = false,
    this.isBuffer = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget body = Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          if (isBuffer)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'BUFFER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: AppColors.textLight,
                ),
              ),
            ),
          Row(
            children: List.generate(shelf.slots.length, (i) {
              final pos = BoardPos(shelfIndex, i);
              return Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _Slot(
                      pos: pos,
                      item: shelf.slots[i].item,
                      selected: selected == pos,
                      onTap: () => onTap(pos),
                      onMove: onMove,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Container(
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isBuffer
                    ? const [Color(0xFFBCAAA4), Color(0xFF8D6E63)]
                    : const [
                        Color(0xFFE8C9A0),
                        Color(0xFFC4956A),
                        Color(0xFF8B5A2B),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          Container(
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF5D3A1A),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
            ),
          ),
        ],
      ),
    );

    if (celebrating) {
      body = body
          .animate()
          .shimmer(duration: 650.ms, color: AppColors.secondary)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.04, 1.04),
            duration: 220.ms,
          );
    }
    return body;
  }
}

class _Slot extends StatelessWidget {
  final BoardPos pos;
  final GameItem? item;
  final bool selected;
  final VoidCallback onTap;
  final void Function(BoardPos from, BoardPos to) onMove;

  const _Slot({
    required this.pos,
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragData>(
      onWillAcceptWithDetails: (d) {
        if (d.data.from == pos) return false;
        return item == null;
      },
      onAcceptWithDetails: (d) => onMove(d.data.from, pos),
      builder: (context, cand, _) {
        final hover = cand.isNotEmpty;
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: hover
                  ? AppColors.success.withValues(alpha: 0.35)
                  : selected
                      ? AppColors.secondary.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hover
                    ? AppColors.success
                    : selected
                        ? AppColors.secondary
                        : Colors.white.withValues(alpha: 0.45),
                width: hover || selected ? 2.5 : 1.2,
              ),
            ),
            child: item == null
                ? null
                : Center(
                    child: Draggable<DragData>(
                      data: DragData(from: pos, item: item!),
                      feedback: Material(
                        color: Colors.transparent,
                        child: GoodsEmoji(
                          item: item!,
                          size: 64,
                          lifting: true,
                        ),
                      ),
                      childWhenDragging: GoodsEmoji(
                        item: item!,
                        size: 48,
                        dimmed: true,
                      ),
                      child: GoodsEmoji(
                        item: item!,
                        size: 52,
                        lifting: selected,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
