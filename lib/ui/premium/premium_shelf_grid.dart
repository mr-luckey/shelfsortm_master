import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../engine/match_engine.dart';
import '../../models/item.dart';
import '../../models/shelf.dart';
import '../widgets/emoji_assets.dart';

/// Static shelf grid with ASMR match-3 sorting (no row movement).
class PremiumShelfGrid extends StatefulWidget {
  static const int colsPerRow = 4;
  static const double cellHeight = 56;
  static const double line = 2;
  static const int spotsPerCell = 3;

  static const EdgeInsets boardPadding = EdgeInsets.fromLTRB(8, 8, 8, 4);

  /// Rows that fit in [outerHeight] — the grid never changes shape between
  /// levels, so the box count only depends on the screen.
  static int rowsFor(double outerHeight) =>
      ((outerHeight - boardPadding.vertical) / cellHeight)
          .floor()
          .clamp(1, 50);

  /// Boxes the board holds. Levels are generated for exactly this count.
  static int boxesFor(double outerHeight) => rowsFor(outerHeight) * colsPerRow;

  final List<Shelf> shelves;
  final int clearingShelf;
  final bool inputLocked;

  /// Layer waiting behind each box, drawn as a single shadow.
  final List<List<GameItem?>?> nextLayers;
  final void Function(BoardPos from, BoardPos to) onMove;

  const PremiumShelfGrid({
    super.key,
    required this.shelves,
    required this.clearingShelf,
    required this.inputLocked,
    required this.onMove,
    this.nextLayers = const [],
  });

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

class _HeldFace {
  final BoardPos from;
  final String type;
  Offset finger;

  _HeldFace({
    required this.from,
    required this.type,
    required this.finger,
  });
}

class _Hit {
  final int shelfIndex;
  final int slot;

  const _Hit({required this.shelfIndex, required this.slot});
}

/// Centers filled drinks as a group on the shelf cavity width.
List<({int slot, double cx})> _centeredFilledLayout(
  List<GameItem?> slots,
  double cavityWidth,
) {
  final filled = <int>[];
  for (var i = 0; i < slots.length; i++) {
    if (slots[i] != null) filled.add(i);
  }
  if (filled.isEmpty) return const [];

  final n = filled.length;
  final slotW = cavityWidth / math.max(n, PremiumShelfGrid.spotsPerCell);
  final totalW = slotW * n;
  final startX = (cavityWidth - totalW) / 2;
  return [
    for (var i = 0; i < n; i++)
      (slot: filled[i], cx: startX + slotW * (i + 0.5)),
  ];
}

/// Same insets as [_paintWoodCell] cavity.
({double left, double width, double floorY}) _cavityMetrics(Rect rect) {
  final w = rect.width;
  final h = rect.height;
  final insetL = w * 0.109;
  final insetR = w * 0.109;
  final insetB = h * 0.146;
  return (
    left: insetL,
    width: w - insetL - insetR,
    floorY: rect.height - insetB,
  );
}

class _PremiumShelfGridState extends State<PremiumShelfGrid>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  final Map<String, ui.Image> _faceImages = {};
  final Set<String> _requested = {};

  double _colWidth = 0;
  int _rows = 0;
  _HeldFace? _held;

  /// Progress of the SOLD stamp on [PremiumShelfGrid.clearingShelf].
  double _sellT = 0;

  static const double _sellDuration = 0.5;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(PremiumShelfGrid old) {
    super.didUpdateWidget(old);
    if (old.clearingShelf != widget.clearingShelf) _sellT = 0;
  }

  @override
  void dispose() {
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
    if (_colWidth <= 0) return null;
    final row = (local.dy / PremiumShelfGrid.cellHeight).floor();
    final col = (local.dx / _colWidth).floor();
    if (row < 0 || row >= _rows) return null;
    if (col < 0 || col >= PremiumShelfGrid.colsPerRow) return null;

    final index = row * PremiumShelfGrid.colsPerRow + col;
    if (index >= widget.shelves.length) return null;

    final slots = [for (final s in widget.shelves[index].slots) s.front];
    final cellLeft = col * _colWidth;
    final cavity = _cavityMetrics(
      Rect.fromLTWH(0, 0, _colWidth, PremiumShelfGrid.cellHeight),
    );
    final localInCavity = local.dx - cellLeft - cavity.left;
    final layout = _centeredFilledLayout(slots, cavity.width);

    var slot = -1;
    if (layout.isNotEmpty) {
      var bestDist = double.infinity;
      for (final e in layout) {
        final d = (localInCavity - e.cx).abs();
        if (d < bestDist) {
          bestDist = d;
          slot = e.slot;
        }
      }
    }
    if (slot < 0) {
      slot = slots.indexWhere((s) => s == null);
      if (slot < 0) slot = 0;
    }

    return _Hit(shelfIndex: index, slot: slot);
  }

  void _onPointerDown(Offset local) {
    if (_held != null || widget.inputLocked) return;
    final hit = _hitTest(local);
    if (hit == null) return;

    final slot = widget.shelves[hit.shelfIndex].slots[hit.slot];
    final item = slot.front;
    if (item == null || slot.frontBlocked || !slot.accessible) return;

    HapticFeedback.selectionClick();
    setState(() {
      _held = _HeldFace(
        from: BoardPos(hit.shelfIndex, hit.slot),
        type: item.type,
        finger: local,
      );
    });
  }

  void _onPointerMove(Offset local) {
    final held = _held;
    if (held == null) return;
    setState(() => held.finger = local);
  }

  void _onPointerUp(Offset local) {
    final held = _held;
    if (held == null) return;
    setState(() => _held = null);

    final hit = _hitTest(local);
    if (hit == null || hit.shelfIndex == held.from.shelfIndex) return;

    final target = widget.shelves[hit.shelfIndex];
    final dest = target.firstEmptyIndex;
    if (dest < 0) return;

    HapticFeedback.lightImpact();
    widget.onMove(held.from, BoardPos(hit.shelfIndex, dest));
  }

  void _onPointerCancel() {
    if (_held == null) return;
    setState(() => _held = null);
  }

  @override
  Widget build(BuildContext context) {
    final held = _held;
    final cells = <_CellKey, List<GameItem?>>{};
    final shadows = <_CellKey, List<GameItem?>>{};

    for (var i = 0; i < widget.shelves.length; i++) {
      final key = _CellKey(
        i ~/ PremiumShelfGrid.colsPerRow,
        i % PremiumShelfGrid.colsPerRow,
      );
      final fronts = <GameItem?>[];
      for (var s = 0; s < widget.shelves[i].slots.length; s++) {
        final item = widget.shelves[i].slots[s].front;
        // The lifted item leaves its spot until the engine commits the move.
        final lifted = held != null &&
            held.from.shelfIndex == i &&
            held.from.slotIndex == s;
        fronts.add(lifted ? null : item);
        if (item != null) _loadFace(item.type);
      }
      cells[key] = fronts;

      final behind = i < widget.nextLayers.length ? widget.nextLayers[i] : null;
      if (behind != null && behind.any((e) => e != null)) {
        shadows[key] = behind;
        for (final item in behind) {
          if (item != null) _loadFace(item.type);
        }
      }
    }

    if (held != null) _loadFace(held.type);

    return LayoutBuilder(
      builder: (context, constraints) {
        _rows = PremiumShelfGrid.rowsFor(constraints.maxHeight);
        final boardH = _rows * PremiumShelfGrid.cellHeight;
        final boardW =
            constraints.maxWidth - PremiumShelfGrid.boardPadding.horizontal;
        _colWidth = boardW / PremiumShelfGrid.colsPerRow;

        return Padding(
          padding: PremiumShelfGrid.boardPadding,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: boardW,
              height: boardH,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _onPointerDown(e.localPosition),
                onPointerMove: (e) => _onPointerMove(e.localPosition),
                onPointerUp: (e) => _onPointerUp(e.localPosition),
                onPointerCancel: (_) => _onPointerCancel(),
                child: CustomPaint(
                  size: Size(boardW, boardH),
                  painter: _ShelfGridPainter(
                    rows: _rows,
                    cols: PremiumShelfGrid.colsPerRow,
                    cellHeight: PremiumShelfGrid.cellHeight,
                    line: PremiumShelfGrid.line,
                    cells: cells,
                    shadows: shadows,
                    faceImages: _faceImages,
                    sellingCell: widget.clearingShelf < 0
                        ? null
                        : _CellKey(
                            widget.clearingShelf ~/
                                PremiumShelfGrid.colsPerRow,
                            widget.clearingShelf %
                                PremiumShelfGrid.colsPerRow,
                          ),
                    sellT: _sellT,
                    held: held == null
                        ? null
                        : (type: held.type, finger: held.finger),
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

/// Pixel colors sampled from the reference wood panel.
abstract final class _WoodCellColors {
  static const frameHi = Color(0xFFE8C830);
  static const frameMid = Color(0xFFD4B018);
  static const frameAmber = Color(0xFFD0780C);
  static const frameRight = Color(0xFFE09A20);
  static const frameDeep = Color(0xFFA85800);
  static const bevelHi = Color(0xFFE8E060);
  static const rimEdge = Color(0xFF4A2804);
  // Cream interior so the emoji art reads clearly against the shelf.
  static const recess = Color(0xFF8A7550);
  static const wallTop = Color(0xFFBCA983);
  static const wallSide = Color(0xFFC6B491);
  static const wallRight = Color(0xFFEFE6D2);
  static const floor = Color(0xFFE3D6B8);
  static const back = Color(0xFFF9F3E4);
  static const backBright = Color(0xFFFFFDF6);
  static const backDark = Color(0xFFEEE4CE);
  static const backEdge = Color(0xFFDACBAA);
  static const innerShade = Color(0xFF9C8A66);
}

void _paintWoodCell(Canvas canvas, Rect rect) {
  final w = rect.width;
  final h = rect.height;
  final r = 0.0;

  // Proportions from reference frame (~644×425).
  final insetL = w * 0.109;
  final insetR = w * 0.109;
  final insetT = h * 0.129;
  final insetB = h * 0.146;
  final rim = math.min(w, h) * 0.055;

  final outer = RRect.fromRectAndRadius(rect, Radius.circular(r));
  final cavity = Rect.fromLTRB(
    rect.left + insetL,
    rect.top + insetT,
    rect.right - insetR,
    rect.bottom - insetB,
  );

  canvas.save();
  canvas.clipRRect(outer);

  // Outer gold frame body.
  canvas.drawRRect(
    outer,
    Paint()
      ..shader = ui.Gradient.linear(
        rect.topCenter,
        rect.bottomRight,
        const [
          _WoodCellColors.frameHi,
          _WoodCellColors.frameMid,
          _WoodCellColors.frameAmber,
          _WoodCellColors.frameRight,
        ],
        const [0.0, 0.28, 0.72, 1.0],
      ),
  );

  // Soft left/top highlight band on the rim.
  canvas.drawRRect(
    outer,
    Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        Offset(rect.left + w * 0.35, rect.top + h * 0.45),
        [
          _WoodCellColors.bevelHi.withValues(alpha: 0.55),
          _WoodCellColors.bevelHi.withValues(alpha: 0.0),
        ],
      ),
  );

  // Inner bevel ring (lighter lip before the recess).
  final lip = RRect.fromRectAndRadius(
    rect.deflate(rim * 0.85),
    Radius.circular(math.max(1.0, r - rim * 0.85)),
  );
  canvas.drawRRect(
    lip,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, rim * 0.55)
      ..color = _WoodCellColors.bevelHi.withValues(alpha: 0.7),
  );

  // Depth walls (trapezoids from outer rim to cavity).
  final wallPaint = Paint()..style = PaintingStyle.fill;

  final topWall = Path()
    ..moveTo(rect.left + rim, rect.top + rim)
    ..lineTo(rect.right - rim, rect.top + rim)
    ..lineTo(cavity.right, cavity.top)
    ..lineTo(cavity.left, cavity.top)
    ..close();
  wallPaint.shader = ui.Gradient.linear(
    Offset(rect.center.dx, rect.top + rim),
    Offset(rect.center.dx, cavity.top),
    const [_WoodCellColors.recess, _WoodCellColors.wallTop, _WoodCellColors.backEdge],
    const [0.0, 0.45, 1.0],
  );
  canvas.drawPath(topWall, wallPaint);

  final leftWall = Path()
    ..moveTo(rect.left + rim, rect.top + rim)
    ..lineTo(cavity.left, cavity.top)
    ..lineTo(cavity.left, cavity.bottom)
    ..lineTo(rect.left + rim, rect.bottom - rim)
    ..close();
  wallPaint.shader = ui.Gradient.linear(
    Offset(rect.left + rim, rect.center.dy),
    Offset(cavity.left, rect.center.dy),
    const [_WoodCellColors.recess, _WoodCellColors.wallSide, _WoodCellColors.backEdge],
    const [0.0, 0.5, 1.0],
  );
  canvas.drawPath(leftWall, wallPaint);

  final rightWall = Path()
    ..moveTo(rect.right - rim, rect.top + rim)
    ..lineTo(cavity.right, cavity.top)
    ..lineTo(cavity.right, cavity.bottom)
    ..lineTo(rect.right - rim, rect.bottom - rim)
    ..close();
  wallPaint.shader = ui.Gradient.linear(
    Offset(rect.right - rim, rect.center.dy),
    Offset(cavity.right, rect.center.dy),
    const [_WoodCellColors.frameDeep, _WoodCellColors.wallRight, _WoodCellColors.backDark],
    const [0.0, 0.45, 1.0],
  );
  canvas.drawPath(rightWall, wallPaint);

  final botWall = Path()
    ..moveTo(rect.left + rim, rect.bottom - rim)
    ..lineTo(cavity.left, cavity.bottom)
    ..lineTo(cavity.right, cavity.bottom)
    ..lineTo(rect.right - rim, rect.bottom - rim)
    ..close();
  wallPaint.shader = ui.Gradient.linear(
    Offset(rect.center.dx, cavity.bottom),
    Offset(rect.center.dx, rect.bottom - rim),
    const [_WoodCellColors.floor, _WoodCellColors.frameAmber],
    const [0.0, 1.0],
  );
  canvas.drawPath(botWall, wallPaint);

  // Recessed wood back panel.
  canvas.drawRect(
    cavity,
    Paint()
      ..shader = ui.Gradient.radial(
        cavity.center,
        math.max(cavity.width, cavity.height) * 0.72,
        const [
          _WoodCellColors.backBright,
          _WoodCellColors.back,
          _WoodCellColors.backDark,
          _WoodCellColors.backEdge,
        ],
        const [0.0, 0.35, 0.75, 1.0],
      ),
  );

  // Vertical wood grain (deterministic per cell).
  final grain = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(0.6, w * 0.008)
    ..strokeCap = StrokeCap.round;
  final rng = math.Random(
    Object.hash(rect.left.round(), rect.top.round(), 0xC311),
  );
  final grainCount = math.max(8, (cavity.width / (w * 0.045)).round());
  for (var i = 0; i < grainCount; i++) {
    final t = (i + 0.5) / grainCount;
    final x = cavity.left + cavity.width * t + (rng.nextDouble() - 0.5) * w * 0.012;
    final dark = rng.nextBool();
    grain.color = (dark ? _WoodCellColors.backEdge : _WoodCellColors.backBright)
        .withValues(alpha: 0.10 + rng.nextDouble() * 0.10);
    final path = Path();
    final steps = 6;
    for (var s = 0; s <= steps; s++) {
      final yy = cavity.top + cavity.height * (s / steps);
      final xx = x + math.sin(s * 1.7 + i) * w * 0.004;
      if (s == 0) {
        path.moveTo(xx, yy);
      } else {
        path.lineTo(xx, yy);
      }
    }
    canvas.drawPath(path, grain);
  }

  // Soft top shadow onto the back panel.
  canvas.drawRect(
    Rect.fromLTWH(cavity.left, cavity.top, cavity.width, cavity.height * 0.32),
    Paint()
      ..shader = ui.Gradient.linear(
        cavity.topCenter,
        Offset(cavity.center.dx, cavity.top + cavity.height * 0.32),
        [
          _WoodCellColors.innerShade.withValues(alpha: 0.34),
          _WoodCellColors.innerShade.withValues(alpha: 0.0),
        ],
      ),
  );

  canvas.restore();

  // Outer rim edge.
  canvas.drawRRect(
    outer,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, rim * 0.22)
      ..color = _WoodCellColors.rimEdge,
  );
}

class _ShelfGridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final double cellHeight;
  final double line;
  final Map<_CellKey, List<GameItem?>> cells;
  final Map<_CellKey, List<GameItem?>> shadows;
  final Map<String, ui.Image> faceImages;
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
    this.shadows = const {},
    this.sellingCell,
    this.sellT = 0,
    this.held,
    this.highlightFree = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final colWidth = size.width / cols;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(
          c * colWidth,
          r * cellHeight,
          colWidth,
          cellHeight,
        );
        _paintWoodCell(canvas, rect);

        final key = _CellKey(r, c);
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
        if (behind != null) _paintShadow(canvas, rect, behind);
        _paintSlots(canvas, rect, slots);
        if (key == sellingCell) _paintSoldStamp(canvas, rect);
      }
    }

    final h = held;
    if (h != null) {
      final image = faceImages[h.type];
      if (image != null) {
        final cell = Rect.fromLTWH(0, 0, colWidth, cellHeight);
        final s = _faceSize(cell, _cavityMetrics(cell).width) * 1.25;
        _drawImage(
          canvas,
          image,
          Rect.fromCenter(center: h.finger, width: s, height: s),
          null,
        );
      }
    }
  }

  /// Sized off one slot so neighbours always keep a clear gap between them.
  double _faceSize(Rect rect, double cavityWidth) {
    final slotW = cavityWidth / PremiumShelfGrid.spotsPerCell;
    return math.min(slotW * 0.82, rect.height * 0.52);
  }

  void _drawImage(
    Canvas canvas,
    ui.Image image,
    Rect dst,
    ColorFilter? filter,
  ) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = filter,
    );
  }

  void _paintSlots(Canvas canvas, Rect rect, List<GameItem?> slots) {
    final cavity = _cavityMetrics(rect);
    final size = _faceSize(rect, cavity.width);
    final layout = _centeredFilledLayout(slots, cavity.width);
    final floorY = rect.top + cavity.floorY;

    for (final e in layout) {
      final item = slots[e.slot];
      if (item == null) continue;
      final image = faceImages[item.type];
      if (image == null) continue;

      // Sit on the wood shelf floor inside the cavity.
      final cx = rect.left + cavity.left + e.cx;
      _paintContactShadow(canvas, cx, floorY, size);
      _drawImage(
        canvas,
        image,
        Rect.fromLTWH(cx - size / 2, floorY - size, size, size),
        null,
      );
    }
  }

  /// Grounds an item so it reads as standing on the shelf, not floating.
  void _paintContactShadow(Canvas canvas, double cx, double floorY, double s) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, floorY - s * 0.03),
        width: s * 0.72,
        height: s * 0.17,
      ),
      Paint()
        ..color = const Color(0xFF6B5836).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
    );
  }

  /// Only the layer directly behind the front is ever drawn.
  void _paintShadow(Canvas canvas, Rect rect, List<GameItem?> behind) {
    final cavity = _cavityMetrics(rect);
    final size = _faceSize(rect, cavity.width) * 0.78;
    final layout = _centeredFilledLayout(behind, cavity.width);
    final floorY = rect.top + cavity.floorY - size * 0.34;

    const filter = ColorFilter.mode(Color(0x59120A04), BlendMode.srcIn);
    for (final e in layout) {
      final item = behind[e.slot];
      if (item == null) continue;
      final image = faceImages[item.type];
      if (image == null) continue;

      final cx = rect.left + cavity.left + e.cx;
      _drawImage(
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
