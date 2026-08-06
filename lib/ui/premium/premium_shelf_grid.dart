import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../engine/match_engine.dart';
import '../../models/item.dart';
import '../../models/shelf.dart';
import 'board_drag.dart';
import 'face_images.dart';
import 'premium_goods_fx.dart';
import 'premium_wood_cell.dart';

/// Layout-driven shelf grid with ASMR match-3 sorting (no row movement).
///
/// [layout] is rows of 1-based shelf ids; `0` is a visual hole. The board
/// never exceeds 4 columns × 10 rows.
class PremiumShelfGrid extends StatefulWidget {
  static const int maxCols = 4;
  static const int maxRows = 10;
  static const double line = 2;
  static const int spotsPerCell = 3;

  /// Target cell height / width used for responsive sizing.
  static const double cellAspect = 56 / 90;
  static const double maxCellWidth = 130;
  static const double minCellWidth = 56;

  /// A tall board squashes its rows rather than narrowing the cupboard.
  static const double minCellAspect = 0.42;

  static const EdgeInsets boardPadding = EdgeInsets.fromLTRB(8, 8, 8, 4);

  final List<List<int>> layout;
  final List<Shelf> shelves;

  /// Boxes playing their sale right now.
  final Set<int> clearingShelves;
  final bool inputLocked;

  /// Layer standing behind the front row of each box.
  final List<List<GameItem?>?> nextLayers;
  final void Function(BoardPos from, BoardPos to) onMove;

  /// Shared with the tray belt so a good can be carried between the two. When
  /// null the grid carries goods on its own.
  final BoardDragController? drag;

  const PremiumShelfGrid({
    super.key,
    required this.layout,
    required this.shelves,
    required this.inputLocked,
    required this.onMove,
    this.clearingShelves = const {},
    this.nextLayers = const [],
    this.drag,
  });

  /// Cell size the board settles on inside [available] space (padding already
  /// taken off). Shared with the board area so a carried good keeps its size.
  ///
  /// The cupboard always spans the width it is given; a ten row board loses
  /// height per row instead of shrinking into a narrow column.
  static Size cellSizeFor(Size available, int rows, int cols) {
    final r = math.max(1, rows);
    final c = math.max(1, cols);
    var cellW = available.width > 0
        ? math.min(available.width / c, maxCellWidth)
        : minCellWidth;
    var cellH = cellW * cellAspect;
    if (available.height > 0 && cellH * r > available.height) {
      cellH = available.height / r;
      // Rows only squash so far; on a very short screen the cupboard gives
      // width back so the whole board still fits.
      if (cellH < cellW * minCellAspect) cellW = cellH / minCellAspect;
    }
    return Size(cellW, cellH);
  }

  @override
  State<PremiumShelfGrid> createState() => _PremiumShelfGridState();
}

class _CellKey {
  final int row;
  final int col;
  const _CellKey(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is _CellKey && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

/// What one box shows: its front row and the layer standing behind it.
class _CellData {
  final int shelfIndex;
  final List<GameItem?> fronts;
  final List<GameItem?>? behind;

  const _CellData({
    required this.shelfIndex,
    required this.fronts,
    this.behind,
  });
}

class _Hit {
  final int shelfIndex;
  final int slot;

  const _Hit({required this.shelfIndex, required this.slot});
}

class _PremiumShelfGridState extends State<PremiumShelfGrid>
    with SingleTickerProviderStateMixin
    implements BoardDropZone {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  final FaceImages _faces = FaceImages.instance;
  final GoodsFx _fx = GoodsFx();
  final FxRepaint _repaint = FxRepaint();
  final StaticLayer _woodLayer = StaticLayer();

  static const String _cellBgAsset =
      'assets/images/premium/cupboards/shelf_cell.png';
  final ValueNotifier<ui.Image?> _cellBg = ValueNotifier<ui.Image?>(null);

  double _colWidth = 0;
  double _cellHeight = 56;
  int _rows = 0;
  int _cols = 0;
  final Map<_CellKey, int> _cellToShelf = {};
  final Map<int, _CellKey> _shelfToCell = {};

  final GlobalKey _boardKey = GlobalKey();
  late BoardDragController _drag;
  late bool _ownsDrag;
  Listenable? _painterRepaint;

  void _rebuildCellMaps() {
    _cellToShelf.clear();
    _shelfToCell.clear();
    final idToIndex = <int, int>{
      for (var i = 0; i < widget.shelves.length; i++)
        widget.shelves[i].shelfId: i,
    };
    final layout = widget.layout;
    _rows = layout.length.clamp(0, PremiumShelfGrid.maxRows);
    _cols = 0;
    for (final row in layout) {
      if (row.length > _cols) _cols = row.length;
    }
    _cols = _cols.clamp(0, PremiumShelfGrid.maxCols);

    for (var r = 0; r < _rows; r++) {
      final row = layout[r];
      for (var c = 0; c < row.length && c < _cols; c++) {
        final id = row[c];
        if (id <= 0) continue;
        final index = idToIndex[id];
        if (index == null) continue;
        final key = _CellKey(r, c);
        _cellToShelf[key] = index;
        _shelfToCell[index] = key;
      }
    }
  }

  bool _hasCell(int r, int c) => _cellToShelf.containsKey(_CellKey(r, c));

  @override
  void initState() {
    super.initState();
    _rebuildCellMaps();
    _attachDrag(widget.drag);
    _ticker = createTicker(_onTick);
    _loadCellBg();
  }

  void _attachDrag(BoardDragController? external) {
    _ownsDrag = external == null;
    _drag = external ?? BoardDragController();
    _drag.register(this);
    _drag.held.addListener(_onHeldChanged);
    _painterRepaint = Listenable.merge([
      _repaint,
      _faces,
      _drag.held,
      _drag.finger,
      _cellBg,
    ]);
  }

  void _detachDrag() {
    _drag.held.removeListener(_onHeldChanged);
    _drag.unregister(this);
    if (_ownsDrag) _drag.dispose();
  }

  /// Picking a good up or letting it go only changes what is painted.
  void _onHeldChanged() => _repaint.ping();

  Future<void> _loadCellBg() async {
    try {
      final data = await rootBundle.load(_cellBgAsset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      final old = _cellBg.value;
      _cellBg.value = frame.image;
      old?.dispose();
    } catch (_) {
      // Missing art — the painted wood cell stays as the background.
    }
  }

  @override
  void didUpdateWidget(PremiumShelfGrid old) {
    super.didUpdateWidget(old);
    if (old.layout != widget.layout || old.shelves != widget.shelves) {
      _rebuildCellMaps();
    }
    if (old.drag != widget.drag) {
      _detachDrag();
      _attachDrag(widget.drag);
    }
    for (final shelfIndex in widget.clearingShelves) {
      if (!old.clearingShelves.contains(shelfIndex)) {
        _fx.startSell(shelfIndex);
      }
    }
    for (final shelfIndex in old.clearingShelves) {
      if (!widget.clearingShelves.contains(shelfIndex)) {
        _fx.stopSell(shelfIndex);
      }
    }
    _startArrivalAnimations(old);
    _syncTicker();
  }

  /// A good that came out of the layer behind slides forward; any other new
  /// good drops into the place it was put down on.
  void _startArrivalAnimations(PremiumShelfGrid old) {
    for (var i = 0; i < widget.shelves.length; i++) {
      final slots = widget.shelves[i].slots;
      final wasSlots = i < old.shelves.length ? old.shelves[i].slots : null;
      final wasBehind =
          i < old.nextLayers.length ? old.nextLayers[i] : null;
      for (var s = 0; s < slots.length; s++) {
        final item = slots[s].front;
        if (item == null) continue;
        final before =
            wasSlots != null && s < wasSlots.length ? wasSlots[s].front : null;
        if (before?.id == item.id) continue;
        final cameFromBehind = wasBehind != null &&
            wasBehind.any((behind) => behind?.id == item.id);
        if (cameFromBehind) {
          _fx.slideForward(item.id);
        } else {
          _fx.land(item.id);
        }
      }
    }
  }

  void _syncTicker() {
    if (_fx.busy) {
      if (!_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      }
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _detachDrag();
    _ticker.dispose();
    _cellBg.value?.dispose();
    _cellBg.dispose();
    _woodLayer.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_last == Duration.zero) {
      _last = elapsed;
      return;
    }
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt > 0 && dt <= 0.1) _fx.advance(dt);
    _repaint.ping();
    if (!_fx.busy) _ticker.stop();
  }

  _Hit? _hitTest(Offset local) {
    if (_colWidth <= 0 || _cellHeight <= 0) return null;
    final row = (local.dy / _cellHeight).floor();
    final col = (local.dx / _colWidth).floor();
    if (row < 0 || row >= _rows) return null;
    if (col < 0 || col >= _cols) return null;

    final index = _cellToShelf[_CellKey(row, col)];
    if (index == null || index >= widget.shelves.length) return null;

    final slotCount = widget.shelves[index].slots.length;
    final cellLeft = col * _colWidth;
    final cavity = cavityMetrics(
      Rect.fromLTWH(0, 0, _colWidth, _cellHeight),
      edgeL: !_hasCell(row, col - 1),
      edgeR: !_hasCell(row, col + 1),
      edgeB: !_hasCell(row + 1, col),
    );
    final localInCavity = local.dx - cellLeft - cavity.left;
    final slotW = cavity.width / spotsPerCell;
    final slot = (localInCavity / slotW).floor().clamp(0, slotCount - 1);

    return _Hit(shelfIndex: index, slot: slot);
  }

  Offset? _localOf(Offset global) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final local = box.globalToLocal(global);
    if (!(Offset.zero & box.size).contains(local)) return null;
    return local;
  }

  Offset _localUnclamped(Offset global) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return global;
    return box.globalToLocal(global);
  }

  @override
  BoardPos? slotAt(Offset global) {
    final local = _localOf(global);
    if (local == null) return null;
    final hit = _hitTest(local);
    return hit == null ? null : BoardPos(hit.shelfIndex, hit.slot);
  }

  @override
  BoardPos? freeSlotAt(Offset global) {
    final pos = slotAt(global);
    if (pos == null) return null;
    if (widget.clearingShelves.contains(pos.shelfIndex)) return null;
    return dropSlot(widget.shelves[pos.shelfIndex].slots, pos);
  }

  @override
  bool isTrayAt(Offset global) => false;

  void _onPointerDown(PointerDownEvent event) {
    if (_drag.held.value != null || widget.inputLocked) return;
    final hit = _hitTest(event.localPosition);
    if (hit == null) return;
    if (widget.clearingShelves.contains(hit.shelfIndex)) return;

    final slot = widget.shelves[hit.shelfIndex].slots[hit.slot];
    final item = slot.front;
    if (item == null || slot.frontBlocked || !slot.accessible) return;

    HapticFeedback.selectionClick();
    _drag.begin(
      HeldGood(from: BoardPos(hit.shelfIndex, hit.slot), type: item.type),
      event.position,
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_drag.held.value == null) return;
    _drag.moveTo(event.position);
  }

  void _onPointerUp(PointerUpEvent event) {
    final held = _drag.held.value;
    if (held == null) return;
    _drag.end();

    final to = _drag.dropAt(event.position);
    if (to == null || to == held.from) return;

    HapticFeedback.lightImpact();
    widget.onMove(held.from, to);
  }

  void _onPointerCancel() {
    if (_drag.held.value == null) return;
    _drag.end();
  }

  /// Where the carried good would land right now, for the drop marker.
  BoardPos? _landingSlot() {
    if (_drag.held.value == null) return null;
    return freeSlotAt(_drag.finger.value);
  }

  @override
  Widget build(BuildContext context) {
    final cells = <_CellKey, _CellData>{};

    for (final e in _cellToShelf.entries) {
      final i = e.value;
      if (i < 0 || i >= widget.shelves.length) continue;
      final fronts = <GameItem?>[];
      for (final slot in widget.shelves[i].slots) {
        final item = slot.front;
        fronts.add(item);
        if (item != null) _faces.request(item.type);
      }

      List<GameItem?>? behind =
          i < widget.nextLayers.length ? widget.nextLayers[i] : null;
      if (behind != null && !behind.any((item) => item != null)) behind = null;
      if (behind != null) {
        for (final item in behind) {
          if (item != null) _faces.request(item.type);
        }
      }

      cells[e.key] = _CellData(shelfIndex: i, fronts: fronts, behind: behind);
    }

    final held = _drag.held.value;
    if (held != null) _faces.request(held.type);

    return LayoutBuilder(
      builder: (context, constraints) {
        _rebuildCellMaps();
        final availW =
            constraints.maxWidth - PremiumShelfGrid.boardPadding.horizontal;
        final availH =
            constraints.maxHeight - PremiumShelfGrid.boardPadding.vertical;
        final rows = math.max(1, _rows);
        final cols = math.max(1, _cols);

        final cell = PremiumShelfGrid.cellSizeFor(
          Size(availW, availH),
          rows,
          cols,
        );
        _colWidth = cell.width;
        _cellHeight = cell.height;
        final boardW = cols * _colWidth;
        final boardH = rows * _cellHeight;

        return Padding(
          padding: PremiumShelfGrid.boardPadding,
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              key: _boardKey,
              width: boardW,
              height: boardH,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: (_) => _onPointerCancel(),
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: Size(boardW, boardH),
                    painter: _ShelfGridPainter(
                      rows: rows,
                      cols: cols,
                      cellHeight: _cellHeight,
                      cells: cells,
                      faces: _faces,
                      cellBg: _cellBg.value,
                      occupied: _cellToShelf.keys.toSet(),
                      fx: _fx,
                      drag: _drag,
                      landing: _landingSlot,
                      wood: _woodLayer,
                      ghost: _ownsDrag ? _localUnclamped : null,
                      repaint: _painterRepaint!,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShelfGridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final double cellHeight;
  final Map<_CellKey, _CellData> cells;
  final FaceImages faces;
  final ui.Image? cellBg;
  final Set<_CellKey> occupied;
  final GoodsFx fx;
  final BoardDragController drag;
  final BoardPos? Function() landing;
  final StaticLayer wood;

  /// Set only when the grid carries the good itself.
  final Offset Function(Offset global)? ghost;

  _ShelfGridPainter({
    required this.rows,
    required this.cols,
    required this.cellHeight,
    required this.cells,
    required this.faces,
    required this.occupied,
    required this.fx,
    required this.drag,
    required this.landing,
    required this.wood,
    required Listenable repaint,
    this.cellBg,
    this.ghost,
  }) : super(repaint: repaint);

  bool _has(int r, int c) => occupied.contains(_CellKey(r, c));

  Rect _cellRect(_CellKey key, double colWidth) => Rect.fromLTWH(
        key.col * colWidth,
        key.row * cellHeight,
        colWidth,
        cellHeight,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final colWidth = size.width / cols;

    _paintWood(canvas, size, colWidth);

    final held = drag.held.value;
    final target = held == null ? null : landing();

    for (final key in occupied) {
      final data = cells[key];
      if (data == null) continue;
      final rect = _cellRect(key, colWidth);
      final edgeL = !_has(key.row, key.col - 1);
      final edgeR = !_has(key.row, key.col + 1);
      final edgeB = !_has(key.row + 1, key.col);
      final cavity = cavityMetrics(
        rect,
        edgeL: edgeL,
        edgeR: edgeR,
        edgeB: edgeB,
      );
      final sellT = fx.sellOf(data.shelfIndex);
      final selling = sellT < 1;

      if (held != null) {
        _paintDropHints(canvas, rect, cavity, data, target);
      }
      _paintBehind(canvas, rect, cavity, data);
      if (selling) {
        // A sale plays inside its own box; nothing spills over the frame.
        canvas.save();
        canvas.clipRect(rect);
      }
      _paintFronts(canvas, rect, cavity, data, held: held, sellT: sellT);
      if (selling) {
        paintSoldStamp(canvas, rect, sellT);
        canvas.restore();
      }
    }

    _paintGhost(canvas, colWidth);
  }

  void _paintWood(Canvas canvas, Size size, double colWidth) {
    final key = Object.hash(
      size.width,
      size.height,
      rows,
      cols,
      cellBg?.hashCode,
      Object.hashAllUnordered(occupied),
    );
    wood.paint(canvas, key, (layer) {
      for (final cell in occupied) {
        final rect = _cellRect(cell, colWidth);
        final bg = cellBg;
        if (bg != null) {
          drawFace(layer, bg, rect, null);
        } else {
          paintWoodCell(
            layer,
            rect,
            board: Offset.zero & size,
            edgeL: !_has(cell.row, cell.col - 1),
            edgeT: !_has(cell.row - 1, cell.col),
            edgeR: !_has(cell.row, cell.col + 1),
            edgeB: !_has(cell.row + 1, cell.col),
          );
        }
      }
    });
  }

  /// Marker on the exact place the good would land (no box rim).
  void _paintDropHints(
    Canvas canvas,
    Rect rect,
    ({double left, double width, double floorY}) cavity,
    _CellData data,
    BoardPos? target,
  ) {
    if (target == null || target.shelfIndex != data.shelfIndex) return;

    final slotW = cavity.width / spotsPerCell;
    final cx = rect.left + cavity.left + slotCenter(target.slotIndex, cavity.width);
    final floorY = rect.top + cavity.floorY;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, floorY - slotW * 0.06),
        width: slotW * 0.86,
        height: slotW * 0.3,
      ),
      Paint()
        ..color = const Color(0xFF66BB6A).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// The layer behind is drawn as the real products in a dark shade, standing
  /// on the shelf floor a step further back.
  void _paintBehind(
    Canvas canvas,
    Rect rect,
    ({double left, double width, double floorY}) cavity,
    _CellData data,
  ) {
    final behind = data.behind;
    if (behind == null) return;
    final full = faceSize(rect, cavity.width);
    final size = full * 0.86;
    // A short step back on the same shelf floor — never hanging in air.
    final baseY = rect.top + cavity.floorY - size * 0.08;

    for (var slot = 0; slot < behind.length; slot++) {
      final item = behind[slot];
      if (item == null) continue;
      final image = faces.of(item.type);
      if (image == null) continue;

      final cx = rect.left + cavity.left + slotCenter(slot, cavity.width);
      paintContactShadow(canvas, cx, baseY, size, strength: 0.7);
      drawFace(
        canvas,
        image,
        Rect.fromLTWH(cx - size / 2, baseY - size, size, size),
        shadeFilter(darken: behindShade),
      );
    }
  }

  void _paintFronts(
    Canvas canvas,
    Rect rect,
    ({double left, double width, double floorY}) cavity,
    _CellData data, {
    required HeldGood? held,
    required double sellT,
  }) {
    final selling = sellT < 1;
    final full = faceSize(rect, cavity.width);
    final floorY = rect.top + cavity.floorY;
    final behindSize = full * 0.86;
    final behindBaseY = floorY - behindSize * 0.08;

    for (var slot = 0; slot < data.fronts.length; slot++) {
      final item = data.fronts[slot];
      if (item == null) continue;
      if (held != null &&
          held.from.shelfIndex == data.shelfIndex &&
          held.from.slotIndex == slot) {
        continue; // in hand
      }
      final image = faces.of(item.type);
      if (image == null) continue;

      final cx = rect.left + cavity.left + slotCenter(slot, cavity.width);
      var size = full;
      var baseY = floorY;
      var darken = 1.0;
      var opacity = 1.0;
      var squash = 0.0;

      final slide = fx.slideOf(item.id);
      if (slide < 1) {
        final p = Curves.easeOutCubic.transform(slide);
        size = ui.lerpDouble(behindSize, full, p)!;
        baseY = ui.lerpDouble(behindBaseY, floorY, p)!;
        darken = ui.lerpDouble(behindShade, 1.0, p)!;
      } else {
        final drop = fx.landOf(item.id);
        if (drop < 1) {
          final pose = landPose(drop, full);
          baseY -= pose.rise;
          squash = pose.squash;
        }
      }
      if (selling) {
        final pose = sellPose(sellT, full);
        size *= pose.scale;
        baseY -= pose.rise;
        opacity = pose.opacity;
      }

      final lift = ((floorY - baseY) / full).clamp(0.0, 1.0);
      if (opacity > 0.05) {
        paintContactShadow(
          canvas,
          cx,
          floorY,
          size * (1 - lift * 0.35),
          strength: (1 - lift) * opacity,
        );
      }
      final w = size * (1 + squash);
      final h = size * (1 - squash);
      drawFace(
        canvas,
        image,
        Rect.fromLTWH(cx - w / 2, baseY - h, w, h),
        darken < 1 || opacity < 1
            ? shadeFilter(darken: darken, opacity: opacity)
            : null,
      );
      if (selling) {
        paintSellBurst(
          canvas,
          Offset(cx, floorY - full * 0.45),
          full * 0.62,
          sellT,
        );
      }
    }
  }

  void _paintGhost(Canvas canvas, double colWidth) {
    final toLocal = ghost;
    final held = drag.held.value;
    if (toLocal == null || held == null) return;
    final image = faces.of(held.type);
    if (image == null) return;

    final cell = Rect.fromLTWH(0, 0, colWidth, cellHeight);
    final s = faceSize(cell, cavityMetrics(cell).width) * 1.25;
    drawFace(
      canvas,
      image,
      Rect.fromCenter(
        center: toLocal(drag.finger.value),
        width: s,
        height: s,
      ),
      null,
    );
  }

  @override
  bool shouldRepaint(covariant _ShelfGridPainter old) => true;
}
