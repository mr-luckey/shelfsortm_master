import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../engine/match_engine.dart';
import '../../models/item.dart';
import '../../models/shelf.dart';
import '../widgets/emoji_assets.dart';
import 'board_drag.dart';
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
  static const double maxCellWidth = 110;
  static const double minCellWidth = 56;

  static const EdgeInsets boardPadding = EdgeInsets.fromLTRB(8, 8, 8, 4);

  final List<List<int>> layout;
  final List<Shelf> shelves;
  final int clearingShelf;
  final bool inputLocked;

  /// Layer waiting behind each box, drawn as a single shadow.
  final List<List<GameItem?>?> nextLayers;
  final void Function(BoardPos from, BoardPos to) onMove;

  /// Shared with the tray belt so a good can be carried between the two. When
  /// null the grid carries goods on its own.
  final BoardDragController? drag;

  const PremiumShelfGrid({
    super.key,
    required this.layout,
    required this.shelves,
    required this.clearingShelf,
    required this.inputLocked,
    required this.onMove,
    this.nextLayers = const [],
    this.drag,
  });

  /// Cell width the board settles on inside [available] space (padding already
  /// taken off). Shared with the board area so a carried good keeps its size.
  static double cellWidthFor(Size available, int rows, int cols) {
    final r = math.max(1, rows);
    final c = math.max(1, cols);
    var cellW = math.min(available.width / c, available.height / (r * cellAspect));
    cellW = cellW.clamp(minCellWidth, maxCellWidth);
    if (cellW * cellAspect * r > available.height && available.height > 0) {
      cellW = available.height / (r * cellAspect);
    }
    if (cellW * c > available.width && available.width > 0) {
      cellW = available.width / c;
    }
    return cellW;
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

  final Map<String, ui.Image> _faceImages = {};
  final Set<String> _requested = {};

  static const String _cellBgAsset =
      'assets/images/premium/cupboards/shelf_cell.png';
  ui.Image? _cellBg;

  double _colWidth = 0;
  double _cellHeight = 56;
  int _rows = 0;
  int _cols = 0;
  final Map<_CellKey, int> _cellToShelf = {};
  final Map<int, _CellKey> _shelfToCell = {};

  final GlobalKey _boardKey = GlobalKey();
  late BoardDragController _drag;
  late bool _ownsDrag;

  /// Progress of the SOLD stamp on [PremiumShelfGrid.clearingShelf].
  double _sellT = 0;

  static const double _sellDuration = 0.5;

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
    _ticker = createTicker(_onTick)..start();
    _loadCellBg();
  }

  void _attachDrag(BoardDragController? external) {
    _ownsDrag = external == null;
    _drag = external ?? BoardDragController();
    _drag.register(this);
    _drag.held.addListener(_onDragChanged);
    // On its own the grid draws the carried good itself, so it needs every
    // finger update; with a shared controller the board area draws it.
    if (_ownsDrag) _drag.finger.addListener(_onDragChanged);
  }

  void _detachDrag() {
    _drag.held.removeListener(_onDragChanged);
    if (_ownsDrag) _drag.finger.removeListener(_onDragChanged);
    _drag.unregister(this);
    if (_ownsDrag) _drag.dispose();
  }

  void _onDragChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCellBg() async {
    try {
      final data = await rootBundle.load(_cellBgAsset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _cellBg = frame.image);
    } catch (_) {
      // Missing art — the painted wood cell stays as the background.
    }
  }

  @override
  void didUpdateWidget(PremiumShelfGrid old) {
    super.didUpdateWidget(old);
    if (old.clearingShelf != widget.clearingShelf) _sellT = 0;
    if (old.layout != widget.layout || old.shelves != widget.shelves) {
      _rebuildCellMaps();
    }
    if (old.drag != widget.drag) {
      _detachDrag();
      _attachDrag(widget.drag);
    }
  }

  @override
  void dispose() {
    _detachDrag();
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _loadFace(String type) async {
    if (!_requested.add(type)) return;
    try {
      final data = await rootBundle.load(EmojiAssets.pathFor(type));
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _faceImages[type] = frame.image);
    } catch (_) {
      // Missing art — slot stays empty visually.
    }
  }

  void _onTick(Duration elapsed) {
    if (_last == Duration.zero) {
      _last = elapsed;
      return;
    }
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0 || dt > 0.1) return;
    if (widget.clearingShelf < 0 || _sellT >= 1) return;
    setState(() => _sellT = (_sellT + dt / _sellDuration).clamp(0.0, 1.0));
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
    final dest = widget.shelves[pos.shelfIndex].firstEmptyIndex;
    if (dest < 0) return null;
    return BoardPos(pos.shelfIndex, dest);
  }

  @override
  bool isTrayAt(Offset global) => false;

  void _onPointerDown(PointerDownEvent event) {
    if (_drag.held.value != null || widget.inputLocked) return;
    final hit = _hitTest(event.localPosition);
    if (hit == null) return;

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
    if (to == null || to.shelfIndex == held.from.shelfIndex) return;

    HapticFeedback.lightImpact();
    widget.onMove(held.from, to);
  }

  void _onPointerCancel() {
    if (_drag.held.value == null) return;
    _drag.end();
  }

  @override
  Widget build(BuildContext context) {
    final held = _drag.held.value;
    final cells = <_CellKey, List<GameItem?>>{};
    final shadows = <_CellKey, List<GameItem?>>{};

    for (final e in _cellToShelf.entries) {
      final i = e.value;
      if (i < 0 || i >= widget.shelves.length) continue;
      final fronts = <GameItem?>[];
      for (var s = 0; s < widget.shelves[i].slots.length; s++) {
        final item = widget.shelves[i].slots[s].front;
        final lifted = held != null &&
            held.from.shelfIndex == i &&
            held.from.slotIndex == s;
        fronts.add(lifted ? null : item);
        if (item != null) _loadFace(item.type);
      }
      cells[e.key] = fronts;

      final behind = i < widget.nextLayers.length ? widget.nextLayers[i] : null;
      if (behind != null && behind.any((item) => item != null)) {
        shadows[e.key] = behind;
        for (final item in behind) {
          if (item != null) _loadFace(item.type);
        }
      }
    }

    if (held != null) _loadFace(held.type);

    return LayoutBuilder(
      builder: (context, constraints) {
        _rebuildCellMaps();
        final availW =
            constraints.maxWidth - PremiumShelfGrid.boardPadding.horizontal;
        final availH =
            constraints.maxHeight - PremiumShelfGrid.boardPadding.vertical;
        final rows = math.max(1, _rows);
        final cols = math.max(1, _cols);

        final cellW = PremiumShelfGrid.cellWidthFor(
          Size(availW, availH),
          rows,
          cols,
        );
        _colWidth = cellW;
        _cellHeight = cellW * PremiumShelfGrid.cellAspect;
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
                child: CustomPaint(
                  size: Size(boardW, boardH),
                  painter: _ShelfGridPainter(
                    rows: rows,
                    cols: cols,
                    cellHeight: _cellHeight,
                    line: PremiumShelfGrid.line,
                    cells: cells,
                    shadows: shadows,
                    faceImages: _faceImages,
                    cellBg: _cellBg,
                    occupied: _cellToShelf.keys.toSet(),
                    sellingCell: widget.clearingShelf < 0
                        ? null
                        : _shelfToCell[widget.clearingShelf],
                    sellT: _sellT,
                    held: held == null || !_ownsDrag
                        ? null
                        : (
                            type: held.type,
                            finger: _localUnclamped(_drag.finger.value),
                          ),
                    highlightFree: held != null,
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
  final double line;
  final Map<_CellKey, List<GameItem?>> cells;
  final Map<_CellKey, List<GameItem?>> shadows;
  final Map<String, ui.Image> faceImages;
  final ui.Image? cellBg;
  final Set<_CellKey> occupied;
  final _CellKey? sellingCell;
  final double sellT;
  final ({String type, Offset finger})? held;
  final bool highlightFree;

  const _ShelfGridPainter({
    required this.rows,
    required this.cols,
    required this.cellHeight,
    required this.line,
    required this.cells,
    required this.faceImages,
    required this.occupied,
    this.cellBg,
    this.shadows = const {},
    this.sellingCell,
    this.sellT = 0,
    this.held,
    this.highlightFree = false,
  });

  bool _has(int r, int c) => occupied.contains(_CellKey(r, c));

  @override
  void paint(Canvas canvas, Size size) {
    final colWidth = size.width / cols;

    for (final key in occupied) {
      final r = key.row;
      final c = key.col;
      final rect = Rect.fromLTWH(
        c * colWidth,
        r * cellHeight,
        colWidth,
        cellHeight,
      );
      final edgeL = !_has(r, c - 1);
      final edgeR = !_has(r, c + 1);
      final edgeT = !_has(r - 1, c);
      final edgeB = !_has(r + 1, c);
      final bg = cellBg;
      if (bg != null) {
        drawFace(canvas, bg, rect, null);
      } else {
        paintWoodCell(
          canvas,
          rect,
          board: Offset.zero & size,
          edgeL: edgeL,
          edgeT: edgeT,
          edgeR: edgeR,
          edgeB: edgeB,
        );
      }

      final slots = cells[key];
      if (slots == null) continue;

      if (highlightFree) {
        final free = slots.where((s) => s == null).length;
        if (free > 0) {
          final glow = Paint()
            ..color = const Color(0x3366BB6A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas.drawRect(rect.deflate(2), glow);
        }
      }

      final behind = shadows[key];
      if (behind != null) {
        _paintShadow(
          canvas,
          rect,
          behind,
          edgeL: edgeL,
          edgeR: edgeR,
          edgeB: edgeB,
        );
      }
      _paintSlots(
        canvas,
        rect,
        slots,
        edgeL: edgeL,
        edgeR: edgeR,
        edgeB: edgeB,
      );
      if (key == sellingCell) _paintSoldStamp(canvas, rect);
    }

    final h = held;
    if (h != null) {
      final image = faceImages[h.type];
      if (image != null) {
        final cell = Rect.fromLTWH(0, 0, colWidth, cellHeight);
        final s = faceSize(cell, cavityMetrics(cell).width) * 1.25;
        drawFace(
          canvas,
          image,
          Rect.fromCenter(center: h.finger, width: s, height: s),
          null,
        );
      }
    }
  }

  void _paintSlots(
    Canvas canvas,
    Rect rect,
    List<GameItem?> slots, {
    bool edgeL = true,
    bool edgeR = true,
    bool edgeB = true,
  }) {
    final cavity = cavityMetrics(rect, edgeL: edgeL, edgeR: edgeR, edgeB: edgeB);
    final size = faceSize(rect, cavity.width);
    final floorY = rect.top + cavity.floorY;

    for (var slot = 0; slot < slots.length; slot++) {
      final item = slots[slot];
      if (item == null) continue;
      final image = faceImages[item.type];
      if (image == null) continue;

      // Sit on the wood shelf floor inside the cavity.
      final cx = rect.left + cavity.left + slotCenter(slot, cavity.width);
      paintContactShadow(canvas, cx, floorY, size);
      drawFace(
        canvas,
        image,
        Rect.fromLTWH(cx - size / 2, floorY - size, size, size),
        null,
      );
    }
  }

  /// Only the layer directly behind the front is ever drawn.
  void _paintShadow(
    Canvas canvas,
    Rect rect,
    List<GameItem?> behind, {
    bool edgeL = true,
    bool edgeR = true,
    bool edgeB = true,
  }) {
    final cavity = cavityMetrics(rect, edgeL: edgeL, edgeR: edgeR, edgeB: edgeB);
    final size = faceSize(rect, cavity.width) * 0.78;
    final floorY = rect.top + cavity.floorY - size * 0.34;

    const filter = ColorFilter.mode(Color(0x59120A04), BlendMode.srcIn);
    for (var slot = 0; slot < behind.length; slot++) {
      final item = behind[slot];
      if (item == null) continue;
      final image = faceImages[item.type];
      if (image == null) continue;

      final cx = rect.left + cavity.left + slotCenter(slot, cavity.width);
      drawFace(
        canvas,
        image,
        Rect.fromLTWH(cx - size / 2, floorY - size, size, size),
        filter,
      );
    }
  }

  /// Stamped straight onto the goods — no door, no cover.
  void _paintSoldStamp(Canvas canvas, Rect rect) {
    final t = sellT.clamp(0.0, 1.0);
    if (t <= 0) return;
    final bounce = Curves.elasticOut.transform(t);
    final scale = 2.2 - 1.2 * bounce;
    final opacity = (t * 3).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(-0.18);
    canvas.scale(scale);

    final stampTp = TextPainter(
      text: TextSpan(
        text: 'SOLD',
        style: TextStyle(
          fontSize: math.min(rect.height * 0.42, 22.0),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: Color.fromRGBO(180, 30, 30, opacity),
          height: 1,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final pad = 4.0;
    final stampRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: stampTp.width + pad * 2,
        height: stampTp.height + pad,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      stampRect,
      Paint()
        ..color = Color.fromRGBO(180, 30, 30, 0.18 * opacity)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      stampRect,
      Paint()
        ..color = Color.fromRGBO(180, 30, 30, 0.85 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    stampTp.paint(canvas, Offset(-stampTp.width / 2, -stampTp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShelfGridPainter old) {
    if (old.rows != rows || old.cols != cols) return true;
    if (old.cellHeight != cellHeight || old.line != line) return true;
    if (old.highlightFree != highlightFree) return true;
    if (old.sellingCell != sellingCell || old.sellT != sellT) return true;
    if (old.held?.type != held?.type || old.held?.finger != held?.finger) {
      return true;
    }
    if (old.cellBg != cellBg) return true;
    if (old.occupied.length != occupied.length) return true;
    if (old.faceImages.length != faceImages.length) return true;
    if (_cellsDiffer(old.cells, cells)) return true;
    if (_cellsDiffer(old.shadows, shadows)) return true;
    return false;
  }

  bool _cellsDiffer(
    Map<_CellKey, List<GameItem?>> a,
    Map<_CellKey, List<GameItem?>> b,
  ) {
    if (a.length != b.length) return true;
    for (final e in b.entries) {
      final o = a[e.key];
      if (o == null || o.length != e.value.length) return true;
      for (var i = 0; i < e.value.length; i++) {
        if (o[i]?.id != e.value[i]?.id) return true;
      }
    }
    return false;
  }
}
