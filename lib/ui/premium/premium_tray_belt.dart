import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../engine/match_engine.dart';
import '../../engine/mechanics/conveyor_tray.dart';
import '../../models/item.dart';
import '../../models/shelf.dart';
import '../widgets/emoji_assets.dart';
import 'board_drag.dart';
import 'premium_wood_cell.dart';

/// The belt of trays that rolls past under the cupboard.
///
/// Trays are ordinary board shelves marked `isDock`, so a good on a tray can be
/// picked up, carried into the cupboard, or matched right where it stands. The
/// belt keeps rolling on its own ticker, which keeps movement smooth without
/// rebuilding the whole board every frame.
class PremiumTrayBelt extends StatefulWidget {
  static const double height = 92;
  static const EdgeInsets beltPadding = EdgeInsets.fromLTRB(0, 2, 0, 6);

  /// Every board shelf, including the cupboard boxes.
  final List<Shelf> shelves;

  /// Tray shelves in belt order.
  final List<int> trayIndices;

  final ConveyorTrayMechanic mechanic;
  final bool inputLocked;
  final BoardDragController drag;
  final void Function(BoardPos from, BoardPos to) onMove;

  const PremiumTrayBelt({
    super.key,
    required this.shelves,
    required this.trayIndices,
    required this.mechanic,
    required this.inputLocked,
    required this.drag,
    required this.onMove,
  });

  @override
  State<PremiumTrayBelt> createState() => _PremiumTrayBeltState();
}

class _PremiumTrayBeltState extends State<PremiumTrayBelt>
    with SingleTickerProviderStateMixin
    implements BoardDropZone {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  final GlobalKey _beltKey = GlobalKey();
  final Map<String, ui.Image> _faceImages = {};
  final Set<String> _requested = {};

  double _trayWidth = 0;
  double _beltHeight = 0;

  @override
  void initState() {
    super.initState();
    widget.drag.register(this);
    widget.drag.held.addListener(_onHeldChanged);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(PremiumTrayBelt old) {
    super.didUpdateWidget(old);
    if (old.drag != widget.drag) {
      old.drag.held.removeListener(_onHeldChanged);
      old.drag.unregister(this);
      widget.drag.register(this);
      widget.drag.held.addListener(_onHeldChanged);
    }
  }

  @override
  void dispose() {
    widget.drag.held.removeListener(_onHeldChanged);
    widget.drag.unregister(this);
    _ticker.dispose();
    super.dispose();
  }

  /// A good lifted off a tray slows the belt until it is placed.
  void _onHeldChanged() {
    final held = widget.drag.held.value;
    widget.mechanic.setCarrying(held != null && held.fromTray);
    if (mounted) setState(() {});
  }

  void _onTick(Duration elapsed) {
    if (_last == Duration.zero) {
      _last = elapsed;
      return;
    }
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0 || dt > 0.1) return;
    widget.mechanic.advance(dt);
    setState(() {});
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
      // Missing art — the place stays empty visually.
    }
  }

  /// Left edge of tray [ordinal] inside the belt window.
  double _trayLeft(int ordinal) =>
      widget.mechanic.positionOf(ordinal) * _trayWidth;

  Rect _trayRect(int ordinal) => Rect.fromLTWH(
        _trayLeft(ordinal),
        0,
        _trayWidth,
        _beltHeight,
      );

  Offset? _localOf(Offset global) {
    final box = _beltKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final local = box.globalToLocal(global);
    if (!(Offset.zero & box.size).contains(local)) return null;
    return local;
  }

  ({int shelfIndex, int slot})? _hitTest(Offset local) {
    if (_trayWidth <= 0) return null;
    for (var i = 0; i < widget.trayIndices.length; i++) {
      final rect = _trayRect(i);
      if (!rect.contains(local)) continue;
      final shelfIndex = widget.trayIndices[i];
      if (shelfIndex >= widget.shelves.length) return null;
      final cavity = cavityMetrics(rect);
      final slotW = cavity.width / spotsPerCell;
      final slotCount = widget.shelves[shelfIndex].slots.length;
      final slot = ((local.dx - rect.left - cavity.left) / slotW)
          .floor()
          .clamp(0, slotCount - 1);
      return (shelfIndex: shelfIndex, slot: slot);
    }
    return null;
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
  bool isTrayAt(Offset global) => slotAt(global) != null;

  void _onPointerDown(PointerDownEvent event) {
    if (widget.drag.held.value != null || widget.inputLocked) return;
    final hit = _hitTest(event.localPosition);
    if (hit == null) return;

    final slot = widget.shelves[hit.shelfIndex].slots[hit.slot];
    final item = slot.front;
    if (item == null || slot.frontBlocked || !slot.accessible) return;

    HapticFeedback.selectionClick();
    widget.drag.begin(
      HeldGood(
        from: BoardPos(hit.shelfIndex, hit.slot),
        type: item.type,
        fromTray: true,
      ),
      event.position,
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (widget.drag.held.value == null) return;
    widget.drag.moveTo(event.position);
  }

  void _onPointerUp(PointerUpEvent event) {
    final held = widget.drag.held.value;
    if (held == null) return;
    widget.drag.end();

    final to = widget.drag.dropAt(event.position);
    if (to == null || to.shelfIndex == held.from.shelfIndex) return;

    HapticFeedback.lightImpact();
    widget.onMove(held.from, to);
  }

  @override
  Widget build(BuildContext context) {
    final held = widget.drag.held.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        _beltHeight = math.min(constraints.maxHeight, PremiumTrayBelt.height);
        _trayWidth = constraints.maxWidth / widget.mechanic.viewportTrays;

        final trays = <({Rect rect, List<GameItem?> slots})>[];
        for (var i = 0; i < widget.trayIndices.length; i++) {
          final rect = _trayRect(i);
          if (rect.right <= 0 || rect.left >= constraints.maxWidth) continue;
          final shelfIndex = widget.trayIndices[i];
          if (shelfIndex >= widget.shelves.length) continue;
          final shelf = widget.shelves[shelfIndex];
          final slots = <GameItem?>[];
          for (var s = 0; s < shelf.slots.length; s++) {
            final item = shelf.slots[s].front;
            final lifted = held != null &&
                held.from.shelfIndex == shelfIndex &&
                held.from.slotIndex == s;
            slots.add(lifted ? null : item);
            if (item != null) _loadFace(item.type);
          }
          trays.add((rect: rect, slots: slots));
        }

        return SizedBox(
          key: _beltKey,
          height: _beltHeight,
          width: constraints.maxWidth,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            child: ClipRect(
              child: CustomPaint(
                size: Size(constraints.maxWidth, _beltHeight),
                painter: _TrayBeltPainter(
                  trays: trays,
                  faceImages: _faceImages,
                  highlightFree: held != null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrayBeltPainter extends CustomPainter {
  final List<({Rect rect, List<GameItem?> slots})> trays;
  final Map<String, ui.Image> faceImages;
  final bool highlightFree;

  const _TrayBeltPainter({
    required this.trays,
    required this.faceImages,
    required this.highlightFree,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // The rail the trays ride on.
    final rail = Rect.fromLTWH(0, size.height - 6, size.width, 6);
    canvas.drawRect(
      rail,
      Paint()
        ..shader = ui.Gradient.linear(
          rail.topCenter,
          rail.bottomCenter,
          const [WoodCellColors.frameAmber, WoodCellColors.frameDeep],
        ),
    );

    for (final tray in trays) {
      final rect = tray.rect;
      paintWoodCell(canvas, rect, board: rect);

      if (highlightFree && tray.slots.any((s) => s == null)) {
        canvas.drawRect(
          rect.deflate(2),
          Paint()
            ..color = const Color(0x3366BB6A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      final cavity = cavityMetrics(rect);
      final s = faceSize(rect, cavity.width);
      final floorY = rect.top + cavity.floorY;
      for (var slot = 0; slot < tray.slots.length; slot++) {
        final item = tray.slots[slot];
        if (item == null) continue;
        final image = faceImages[item.type];
        if (image == null) continue;
        final cx = rect.left + cavity.left + slotCenter(slot, cavity.width);
        paintContactShadow(canvas, cx, floorY, s);
        drawFace(
          canvas,
          image,
          Rect.fromLTWH(cx - s / 2, floorY - s, s, s),
          null,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrayBeltPainter old) {
    if (old.highlightFree != highlightFree) return true;
    if (old.faceImages.length != faceImages.length) return true;
    if (old.trays.length != trays.length) return true;
    for (var i = 0; i < trays.length; i++) {
      if (old.trays[i].rect != trays[i].rect) return true;
      final a = old.trays[i].slots;
      final b = trays[i].slots;
      if (a.length != b.length) return true;
      for (var s = 0; s < b.length; s++) {
        if (a[s]?.id != b[s]?.id) return true;
      }
    }
    return false;
  }
}
