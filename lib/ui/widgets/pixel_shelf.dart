import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../engine/match_engine.dart';
import '../../models/item.dart';
import '../../models/shelf.dart';
import '../theme/shelf_look.dart';
import 'goods_emoji.dart';

class DragData {
  final BoardPos from;
  final GameItem item;
  const DragData({required this.from, required this.item});
}

/// Goods Sort™ cabinet compartment — 3 emoji slots + closing doors.
class CabinetShelf extends StatelessWidget {
  final Shelf shelf;
  final int shelfIndex;
  final BoardPos? selected;
  final bool celebrating;
  final bool opening;
  final bool isDone;
  final double scale;
  final ShelfLook look;
  final LevelSpice spice;
  final void Function(BoardPos pos) onTap;
  final void Function(BoardPos from, BoardPos to) onMove;

  const CabinetShelf({
    super.key,
    required this.shelf,
    required this.shelfIndex,
    required this.onTap,
    required this.onMove,
    required this.look,
    this.spice = LevelSpice.classic,
    this.selected,
    this.celebrating = false,
    this.opening = false,
    this.isDone = false,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return SizedBox(
        height: 92 * scale,
        child: Opacity(
          opacity: 0.35,
          child: Container(
            margin: EdgeInsets.all(4 * scale),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12 * scale),
              border: Border.all(color: Colors.white54),
            ),
            child: Center(
              child: Icon(Icons.check_circle, color: Colors.white70, size: 28.sp),
            ),
          ),
        ),
      );
    }

    final doorClosed = celebrating;
    final doorOpening = opening;

    Widget body = Container(
      margin: EdgeInsets.symmetric(horizontal: 3 * scale, vertical: 3 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14 * scale),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF5D4037),
            const Color(0xFF3E2723),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14 * scale),
        child: Stack(
          children: [
            // Inner cabinet recess
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(look.plank.first, Colors.black, 0.35)!,
                      Color.lerp(look.plank.last, Colors.black, 0.55)!,
                    ],
                  ),
                ),
              ),
            ),
            // Emoji row on wooden plank
            Padding(
              padding: EdgeInsets.fromLTRB(4 * scale, 6 * scale, 4 * scale, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 58 * scale,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(shelf.slots.length, (i) {
                        final pos = BoardPos(shelfIndex, i);
                        final slot = shelf.slots[i];
                        return Expanded(
                          child: _Slot(
                            pos: pos,
                            front: slot.front,
                            selected: selected == pos,
                            scale: scale,
                            blocked: slot.frontBlocked,
                            isLocked: slot.isLocked ||
                                (slot.front?.isLocked ?? false),
                            isFrozen: slot.freezeLayers > 0 ||
                                (slot.front?.isFrozen ?? false),
                            isMystery: slot.isMystery ||
                                (slot.front?.isMystery ?? false),
                            accessible: slot.accessible,
                            hidden: doorClosed && !doorOpening,
                            onTap: () => onTap(pos),
                            onMove: onMove,
                          ),
                        );
                      }),
                    ),
                  ),
                  // Wooden plank lip
                  Container(
                    height: 10 * scale,
                    margin: EdgeInsets.symmetric(horizontal: 2 * scale),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4 * scale),
                      gradient: LinearGradient(
                        colors: look.plank,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 3,
                          offset: Offset(0, 2 * scale),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                ],
              ),
            ),
            // Glass doors (close on match, open on new wave)
            if (doorClosed || doorOpening)
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: _GlassDoor(
                        closed: doorClosed && !doorOpening,
                        opening: doorOpening,
                        left: true,
                        scale: scale,
                      ),
                    ),
                    Expanded(
                      child: _GlassDoor(
                        closed: doorClosed && !doorOpening,
                        opening: doorOpening,
                        left: false,
                        scale: scale,
                      ),
                    ),
                  ],
                ),
              ),
            if (celebrating && !opening)
              Positioned(
                top: 4.h,
                right: 4.w,
                child: MatchBurst(color: look.accent, size: 50 * scale),
              ),
          ],
        ),
      ),
    );

    if (opening) {
      body = body
          .animate()
          .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1, 1),
            duration: 420.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 200.ms);
    }

    if (shelf.slideOffset != 0) {
      body = Transform.translate(
        offset: Offset(shelf.slideOffset * 16.0 * scale, 0),
        child: body,
      );
    }

    return body;
  }
}

class _GlassDoor extends StatelessWidget {
  final bool closed;
  final bool opening;
  final bool left;
  final double scale;

  const _GlassDoor({
    required this.closed,
    required this.opening,
    required this.left,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final shut = closed && !opening;
    final offsetX = shut ? 0.0 : (left ? -1.0 : 1.0) * 40 * scale;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
      transform: Matrix4.translationValues(offsetX, 0, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: left ? Alignment.centerLeft : Alignment.centerRight,
          end: left ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            Colors.white.withValues(alpha: shut ? 0.55 : 0.05),
            Colors.white.withValues(alpha: shut ? 0.25 : 0.0),
          ],
        ),
        border: Border(
          right: left ? BorderSide(color: Colors.white.withValues(alpha: 0.4)) : BorderSide.none,
          left: !left ? BorderSide(color: Colors.white.withValues(alpha: 0.4)) : BorderSide.none,
        ),
      ),
      child: shut
          ? Center(
              child: Icon(
                Icons.shopping_basket_outlined,
                color: Colors.white.withValues(alpha: 0.35),
                size: 18 * scale,
              ),
            )
          : null,
    );
  }
}

class _Slot extends StatelessWidget {
  final BoardPos pos;
  final GameItem? front;
  final bool selected;
  final double scale;
  final bool blocked;
  final bool isLocked;
  final bool isFrozen;
  final bool isMystery;
  final bool accessible;
  final bool hidden;
  final VoidCallback onTap;
  final void Function(BoardPos from, BoardPos to) onMove;

  const _Slot({
    required this.pos,
    required this.front,
    required this.selected,
    required this.scale,
    required this.onTap,
    required this.onMove,
    this.blocked = false,
    this.isLocked = false,
    this.isFrozen = false,
    this.isMystery = false,
    this.accessible = true,
    this.hidden = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => _build(_fitSize(box)),
    );
  }

  /// An on-shelf [GoodsEmoji] draws a tile of `size * 0.88`, so grow the size
  /// until that tile fills the slot instead of staying at a fixed 44.
  double _fitSize(BoxConstraints box) {
    final available = math.min(box.maxWidth - 4 * scale, box.maxHeight);
    if (!available.isFinite) return 44 * scale;
    return math.max(44 * scale, available / 0.88);
  }

  Widget _build(double emojiSize) {
    return DragTarget<DragData>(
      onWillAcceptWithDetails: (d) {
        if (hidden || d.data.from == pos) return false;
        if (!accessible) return false;
        return front == null;
      },
      onAcceptWithDetails: (d) => onMove(d.data.from, pos),
      builder: (context, cand, _) {
        final hover = cand.isNotEmpty;
        return GestureDetector(
          onTap: hidden ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: EdgeInsets.symmetric(horizontal: 2 * scale),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10 * scale),
              border: selected || hover
                  ? Border.all(
                      color: hover ? AppColors.success : AppColors.secondary,
                      width: 2,
                    )
                  : null,
            ),
            child: Opacity(
              opacity: hidden ? 0 : (accessible ? 1 : 0.4),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  if (front == null && !hidden)
                    Positioned(
                      bottom: 4 * scale,
                      left: 8 * scale,
                      right: 8 * scale,
                      child: Container(
                        height: 3 * scale,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: hover
                              ? AppColors.success.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  if (front != null && !hidden)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: blocked
                          ? GoodsEmoji(
                              item: front!,
                              size: emojiSize,
                              dimmed: true,
                              onShelf: true,
                            )
                          : Draggable<DragData>(
                              data: DragData(from: pos, item: front!),
                              feedback: Material(
                                color: Colors.transparent,
                                child: GoodsEmoji(
                                  item: front!,
                                  size: emojiSize * 1.18,
                                  lifting: true,
                                  onShelf: true,
                                ),
                              ),
                              childWhenDragging: GoodsEmoji(
                                item: front!,
                                size: emojiSize * 0.82,
                                dimmed: true,
                                onShelf: true,
                              ),
                              child: GoodsEmoji(
                                item: front!,
                                size: emojiSize,
                                lifting: selected,
                                onShelf: true,
                              ),
                            ),
                    ),
                  if (isLocked)
                    Positioned(
                      top: 0,
                      child: Icon(Icons.lock, size: 12 * scale, color: Colors.amber),
                    ),
                  if (isFrozen)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.lightBlueAccent.withValues(alpha: 0.3),
                        ),
                        child: Icon(Icons.ac_unit, size: 16 * scale, color: Colors.white),
                      ),
                    ),
                  if (isMystery && !isFrozen)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(Icons.help_outline, size: 12 * scale, color: Colors.purpleAccent),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
