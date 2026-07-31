import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../engine/match_engine.dart';
import '../../models/item.dart';
import '../../models/shelf.dart';
import '../widgets/emoji_assets.dart';
import 'modular_cupboard_painter.dart';
import 'toy_item_widget.dart';

class PremiumDragData {
  final BoardPos from;
  final GameItem item;
  const PremiumDragData({required this.from, required this.item});
}

/// Modular ornate cupboard that grows with [levelId] (up to 5×7).
/// Products sit on each cubby floor — clipped so they never cut through wood.
class PremiumWoodCupboard extends StatelessWidget {
  final List<List<int>> layout;
  final List<Shelf> shelves;
  final BoardPos? selected;
  final int clearingShelf;
  final int openingShelf;
  final Set<int> finishedShelves;
  final bool inputLocked;
  final int? levelId;

  /// Layer waiting behind each box, drawn as a shadow.
  final List<List<GameItem?>?> nextLayers;
  final void Function(BoardPos) onTap;
  final void Function(BoardPos from, BoardPos to) onMove;

  const PremiumWoodCupboard({
    super.key,
    required this.layout,
    required this.shelves,
    required this.selected,
    required this.clearingShelf,
    required this.openingShelf,
    required this.finishedShelves,
    required this.inputLocked,
    required this.onTap,
    required this.onMove,
    this.levelId,
    this.nextLayers = const [],
  });

  @override
  Widget build(BuildContext context) {
    final idToIndex = <int, int>{};
    for (var i = 0; i < shelves.length; i++) {
      idToIndex[shelves[i].shelfId] = i;
    }

    final rows = layout.length;
    final cols = layout.fold<int>(0, (n, row) => math.max(n, row.length));
    if (rows == 0 || cols == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Match cubby_unit.png aspect (~603×372).
        const cellWh = 1.62; // cubby width / height
        const frameW = 1 -
            ModularCupboardPainter.insetL -
            ModularCupboardPainter.insetR;
        const frameH = 1 -
            ModularCupboardPainter.insetT -
            ModularCupboardPainter.insetB;
        final aspect = cellWh * (frameH / frameW) * (cols / rows);
        var h = constraints.maxHeight * 0.99;
        var w = h * aspect;
        if (w > constraints.maxWidth * 0.98) {
          w = constraints.maxWidth * 0.98;
          h = w / aspect;
        }

        return Center(
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: ModularCupboardPainter(rows: rows, cols: cols),
                  size: Size(w, h),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    w * ModularCupboardPainter.insetL,
                    h * ModularCupboardPainter.insetT,
                    w * ModularCupboardPainter.insetR,
                    h * ModularCupboardPainter.insetB,
                  ),
                  child: Column(
                    children: [
                      for (var r = 0; r < rows; r++)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var c = 0; c < cols; c++)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        IgnorePointer(
                                          child: Image.asset(
                                            'assets/images/premium/cupboards/cubby_unit.png',
                                            fit: BoxFit.fill,
                                            filterQuality: FilterQuality.medium,
                                          ),
                                        ),
                                        _buildCell(
                                          c < layout[r].length
                                              ? layout[r][c]
                                              : 0,
                                          idToIndex,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(int shelfId, Map<int, int> idToIndex) {
    if (shelfId == 0) return const SizedBox.shrink();
    final idx = idToIndex[shelfId];
    if (idx == null) return const SizedBox.shrink();
    return _ShelfCubby(
      shelf: shelves[idx],
      shelfIndex: idx,
      selected: selected,
      celebrating: clearingShelf == idx,
      opening: openingShelf == idx,
      isDone: finishedShelves.contains(idx),
      inputLocked: inputLocked,
      nextLayer: idx < nextLayers.length ? nextLayers[idx] : null,
      onTap: onTap,
      onMove: onMove,
    );
  }
}

class _ShelfCubby extends StatelessWidget {
  final Shelf shelf;
  final int shelfIndex;
  final BoardPos? selected;
  final bool celebrating;
  final bool opening;
  final bool isDone;
  final bool inputLocked;
  final List<GameItem?>? nextLayer;
  final void Function(BoardPos) onTap;
  final void Function(BoardPos from, BoardPos to) onMove;

  const _ShelfCubby({
    required this.shelf,
    required this.shelfIndex,
    required this.selected,
    required this.celebrating,
    required this.opening,
    required this.isDone,
    required this.inputLocked,
    required this.nextLayer,
    required this.onTap,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Inset products into the open cavity of cubby_unit.png.
        final padX = c.maxWidth * 0.07;
        final floorPad = c.maxHeight * 0.22; // above decorative base + lip
        final topClear = c.maxHeight * 0.08;
        final usableW = c.maxWidth - padX * 2;
        final usableH =
            (c.maxHeight - floorPad - topClear).clamp(16.0, c.maxHeight);
        final byW = usableW / 3.02;
        final byH = usableH;
        // Prefer height fill on short shelves; never exceed width slot.
        final itemSize = math.min(byW, byH * 1.02).clamp(22.0, 140.0);

        Widget products = ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: padX,
                right: padX,
                bottom: floorPad,
              ),
              child: SizedBox(
                height: itemSize,
                width: usableW,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(shelf.slots.length, (i) {
                    final pos = BoardPos(shelfIndex, i);
                    final slot = shelf.slots[i];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.5),
                        child: _Slot(
                          pos: pos,
                          front: slot.front,
                          selected: selected == pos,
                          itemSize: itemSize,
                          hidden: false,
                          accessible: slot.accessible && !inputLocked,
                          blocked: slot.frontBlocked,
                          onTap: () {
                            if (!inputLocked) onTap(pos);
                          },
                          onMove: onMove,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );

        if (opening) {
          products = products
              .animate()
              .slideY(
                begin: 0.12,
                end: 0,
                duration: 360.ms,
                curve: Curves.easeOutCubic,
              )
              .fadeIn(duration: 180.ms);
        }

        final behind = nextLayer;
        final showShadow = behind != null && behind.any((e) => e != null);

        return Stack(
          fit: StackFit.expand,
          children: [
            if (showShadow)
              IgnorePointer(
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: padX,
                        right: padX,
                        bottom: floorPad + itemSize * 0.30,
                      ),
                      child: SizedBox(
                        height: itemSize * 0.74,
                        width: usableW,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(shelf.slots.length, (i) {
                            final item = i < behind.length ? behind[i] : null;
                            return Expanded(
                              child: item == null
                                  ? const SizedBox.shrink()
                                  : _LayerShadow(
                                      item: item,
                                      size: itemSize * 0.74,
                                    ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            products,
            if (celebrating && !opening)
              IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.only(bottom: floorPad * 0.6),
                  child: _SoldStamp(size: itemSize),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Silhouette of the layer stacked behind the current one.
class _LayerShadow extends StatelessWidget {
  final GameItem item;
  final double size;

  const _LayerShadow({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.32,
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0xFF120A04),
          BlendMode.srcATop,
        ),
        child: Image.asset(
          EmojiAssets.pathFor(item.type),
          width: size,
          height: size,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// Stamped straight onto the goods when a set sells — no door, no cover.
class _SoldStamp extends StatelessWidget {
  final double size;

  const _SoldStamp({required this.size});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFFB41E1E);
    return Center(
      child: Transform.rotate(
        angle: -0.18,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: size * 0.16,
            vertical: size * 0.05,
          ),
          decoration: BoxDecoration(
            color: ink.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: ink.withValues(alpha: 0.9), width: 2.2),
          ),
          child: Text(
            'SOLD',
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              height: 1,
              fontSize: (size * 0.34).clamp(10.0, 22.0),
            ),
          ),
        ),
      )
          .animate()
          .scale(
            begin: const Offset(2.1, 2.1),
            end: const Offset(1, 1),
            duration: 260.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 120.ms),
    );
  }
}

class _Slot extends StatelessWidget {
  final BoardPos pos;
  final GameItem? front;
  final bool selected;
  final double itemSize;
  final bool hidden;
  final bool accessible;
  final bool blocked;
  final VoidCallback onTap;
  final void Function(BoardPos from, BoardPos to) onMove;

  const _Slot({
    required this.pos,
    required this.front,
    required this.selected,
    required this.itemSize,
    required this.hidden,
    required this.accessible,
    required this.blocked,
    required this.onTap,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<PremiumDragData>(
      onWillAcceptWithDetails: (d) {
        if (hidden || d.data.from == pos || !accessible) return false;
        return front == null;
      },
      onAcceptWithDetails: (d) => onMove(d.data.from, pos),
      builder: (context, cand, _) {
        final hover = cand.isNotEmpty;
        return GestureDetector(
          onTap: hidden ? null : onTap,
          child: Container(
            alignment: Alignment.bottomCenter,
            decoration: selected || hover
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: hover
                          ? const Color(0xFF66BB6A)
                          : const Color(0xFFFFD54F),
                      width: 2,
                    ),
                  )
                : null,
            child: Opacity(
              opacity: hidden ? 0 : (accessible ? 1 : 0.4),
              child: front == null
                  ? const SizedBox.shrink()
                  : blocked
                      ? ToyItemWidget.fromItem(
                          item: front!,
                          size: itemSize,
                          dimmed: true,
                        )
                      : Draggable<PremiumDragData>(
                          data: PremiumDragData(from: pos, item: front!),
                          feedback: Material(
                            color: Colors.transparent,
                            child: ToyItemWidget.fromItem(
                              item: front!,
                              size: itemSize * 1.08,
                              lifting: true,
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.15,
                            child: ToyItemWidget.fromItem(
                              item: front!,
                              size: itemSize * 0.8,
                            ),
                          ),
                          child: ToyItemWidget.fromItem(
                            item: front!,
                            size: itemSize,
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
