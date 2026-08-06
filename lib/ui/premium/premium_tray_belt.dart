import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/audio_cubit.dart';
import '../../engine/match_engine.dart';
import '../../engine/mechanics/conveyor_tray.dart';
import '../../models/item.dart';
import '../../models/shelf.dart';
import 'board_drag.dart';
import 'face_images.dart';
import 'premium_goods_fx.dart';
import 'premium_tray_plank.dart';
import 'premium_wood_cell.dart';

/// The belt of thin wooden trays that rolls past under the cupboard.
///
/// Trays are ordinary board shelves marked `isDock`, so a good on a tray can be
/// picked up, carried into the cupboard, or matched right where it stands. The
/// belt rolls on its own ticker and repaints without rebuilding the board, which
/// keeps movement smooth at 60 FPS.
class PremiumTrayBelt extends StatefulWidget {
  static const double height = 66;
  static const EdgeInsets beltPadding = EdgeInsets.fromLTRB(0, 2, 0, 6);

  /// Every board shelf, including the cupboard boxes.
  final List<Shelf> shelves;

  /// Tray shelves in belt order.
  final List<int> trayIndices;

  final ConveyorTrayMechanic mechanic;
  final bool inputLocked;
  final BoardDragController drag;
  final void Function(BoardPos from, BoardPos to) onMove;

  /// Trays playing their sale right now.
  final Set<int> clearingShelves;

  /// Layer standing behind the front row of every shelf, trays included.
  final List<List<GameItem?>?> nextLayers;

  const PremiumTrayBelt({
    super.key,
    required this.shelves,
    required this.trayIndices,
    required this.mechanic,
    required this.inputLocked,
    required this.drag,
    required this.onMove,
    this.clearingShelves = const {},
    this.nextLayers = const [],
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
  final FaceImages _faces = FaceImages.instance;
  final GoodsFx _fx = GoodsFx();
  final FxRepaint _repaint = FxRepaint();
  late Listenable _painterRepaint;

  double _trayWidth = 0;
  double _beltHeight = 0;

  @override
  void initState() {
    super.initState();
    widget.drag.register(this);
    widget.drag.held.addListener(_onHeldChanged);
    _painterRepaint = Listenable.merge([_repaint, _faces, widget.drag.held]);
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
      _painterRepaint = Listenable.merge([_repaint, _faces, widget.drag.held]);
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
  }

  /// A good that came out of the layer behind slides forward; any other new
  /// good drops onto the board where it was put down.
  void _startArrivalAnimations(PremiumTrayBelt old) {
    for (final index in widget.trayIndices) {
      if (index >= widget.shelves.length) continue;
      final slots = widget.shelves[index].slots;
      final wasSlots =
          index < old.shelves.length ? old.shelves[index].slots : null;
      final wasBehind =
          index < old.nextLayers.length ? old.nextLayers[index] : null;
      for (var s = 0; s < slots.length; s++) {
        final item = slots[s].front;
        if (item == null) continue;
        final before =
            wasSlots != null && s < wasSlots.length ? wasSlots[s].front : null;
        if (before?.id == item.id) continue;
        if (wasBehind != null &&
            wasBehind.any((behind) => behind?.id == item.id)) {
          _fx.slideForward(item.id);
        } else {
          _fx.land(item.id);
        }
      }
    }
  }

  @override
  void dispose() {
    widget.drag.held.removeListener(_onHeldChanged);
    widget.drag.unregister(this);
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  /// A good lifted off a tray slows the belt until it is placed.
  void _onHeldChanged() {
    final held = widget.drag.held.value;
    widget.mechanic.setCarrying(held != null && held.fromTray);
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
    _fx.advance(dt);
    _repaint.ping();
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
      final surface = trayPlankSurface(rect);
      final slotW = surface.width / spotsPerCell;
      final slotCount = widget.shelves[shelfIndex].slots.length;
      final slot = ((local.dx - surface.left) / slotW)
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
    if (widget.clearingShelves.contains(pos.shelfIndex)) return null;
    return dropSlot(widget.shelves[pos.shelfIndex].slots, pos);
  }

  @override
  bool isTrayAt(Offset global) => slotAt(global) != null;

  void _onPointerDown(PointerDownEvent event) {
    if (widget.drag.held.value != null || widget.inputLocked) return;
    final hit = _hitTest(event.localPosition);
    if (hit == null) return;
    if (widget.clearingShelves.contains(hit.shelfIndex)) return;

    final slot = widget.shelves[hit.shelfIndex].slots[hit.slot];
    final item = slot.front;
    if (item == null || slot.frontBlocked || !slot.accessible) return;

    context.read<AudioCubit>().playPick();
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
    if (to == null || to == held.from) return;

    context.read<AudioCubit>().playPlace();
    widget.onMove(held.from, to);
  }

  /// Where the carried good would land right now, for the drop marker.
  BoardPos? _landingSlot() {
    if (widget.drag.held.value == null) return null;
    return freeSlotAt(widget.drag.finger.value);
  }

  @override
  Widget build(BuildContext context) {
    for (final index in widget.trayIndices) {
      if (index >= widget.shelves.length) continue;
      for (final slot in widget.shelves[index].slots) {
        final item = slot.front;
        if (item != null) _faces.request(item.type);
      }
      final behind =
          index < widget.nextLayers.length ? widget.nextLayers[index] : null;
      if (behind == null) continue;
      for (final item in behind) {
        if (item != null) _faces.request(item.type);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _beltHeight = math.min(constraints.maxHeight, PremiumTrayBelt.height);
        _trayWidth = constraints.maxWidth / widget.mechanic.viewportTrays;

        return SizedBox(
          key: _beltKey,
          height: _beltHeight,
          width: constraints.maxWidth,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            child: RepaintBoundary(
              child: ClipRect(
                child: CustomPaint(
                  size: Size(constraints.maxWidth, _beltHeight),
                  painter: _TrayBeltPainter(
                    shelves: widget.shelves,
                    trayIndices: widget.trayIndices,
                    nextLayers: widget.nextLayers,
                    mechanic: widget.mechanic,
                    faces: _faces,
                    fx: _fx,
                    drag: widget.drag,
                    landing: _landingSlot,
                    repaint: _painterRepaint,
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

class _TrayBeltPainter extends CustomPainter {
  final List<Shelf> shelves;
  final List<int> trayIndices;
  final List<List<GameItem?>?> nextLayers;
  final ConveyorTrayMechanic mechanic;
  final FaceImages faces;
  final GoodsFx fx;
  final BoardDragController drag;
  final BoardPos? Function() landing;

  _TrayBeltPainter({
    required this.shelves,
    required this.trayIndices,
    required this.nextLayers,
    required this.mechanic,
    required this.faces,
    required this.fx,
    required this.drag,
    required this.landing,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (mechanic.viewportTrays <= 0) return;
    final trayWidth = size.width / mechanic.viewportTrays;
    final held = drag.held.value;
    final target = held == null ? null : landing();

    for (var i = 0; i < trayIndices.length; i++) {
      final rect = Rect.fromLTWH(
        mechanic.positionOf(i) * trayWidth,
        0,
        trayWidth,
        size.height,
      );
      if (rect.right <= 0 || rect.left >= size.width) continue;
      final shelfIndex = trayIndices[i];
      if (shelfIndex >= shelves.length) continue;
      final shelf = shelves[shelfIndex];

      final surface = paintTrayPlank(canvas, rect);
      if (held != null && shelf.slots.any((s) => s.isEmpty)) {
        paintPlankFreeGlow(canvas, rect, surface);
      }

      // Goods stand on the board, sized like the ones inside the cupboard and
      // capped by the headroom above the plank. Goods are a touch wider than
      // their place, so the outer two are pulled in to stay on the board.
      final slotW = surface.width / spotsPerCell;
      final full =
          math.min(slotW * 1.18, (surface.surfaceY - rect.top) * 0.94);
      final overhang = math.max(0.0, full - slotW);
      final band = surface.width - overhang;
      double centerOf(int slot) =>
          surface.left + overhang / 2 + slotCenter(slot, band);

      final sellT = fx.sellOf(shelfIndex);
      final selling = sellT < 1;
      final behind =
          shelfIndex < nextLayers.length ? nextLayers[shelfIndex] : null;
      final behindSize = full * 0.86;
      final behindBaseY = surface.surfaceY - behindSize * 0.08;

      if (behind != null) {
        for (var slot = 0; slot < behind.length; slot++) {
          final item = behind[slot];
          if (item == null) continue;
          final image = faces.of(item.type);
          if (image == null) continue;
          final cx = centerOf(slot);
          paintContactShadow(canvas, cx, behindBaseY, behindSize,
              strength: 0.7);
          drawFace(
            canvas,
            image,
            Rect.fromLTWH(
              cx - behindSize / 2,
              behindBaseY - behindSize,
              behindSize,
              behindSize,
            ),
            shadeFilter(darken: behindShade),
          );
        }
      }

      if (target != null && target.shelfIndex == shelfIndex) {
        final cx = centerOf(target.slotIndex);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, surface.surfaceY - slotW * 0.05),
            width: slotW * 0.86,
            height: slotW * 0.28,
          ),
          Paint()
            ..color = const Color(0xFF66BB6A).withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      if (selling) {
        // A sale stays over its own tray — nothing spills onto the next one.
        canvas.save();
        canvas.clipRect(rect);
      }
      for (var slot = 0; slot < shelf.slots.length; slot++) {
        final item = shelf.slots[slot].front;
        if (item == null) continue;
        if (held != null &&
            held.from.shelfIndex == shelfIndex &&
            held.from.slotIndex == slot) {
          continue; // in hand
        }
        final image = faces.of(item.type);
        if (image == null) continue;

        final cx = centerOf(slot);
        var s = full;
        var baseY = surface.surfaceY;
        var darken = 1.0;
        var opacity = 1.0;
        var squash = 0.0;

        final slide = fx.slideOf(item.id);
        if (slide < 1) {
          final p = Curves.easeOutCubic.transform(slide);
          s = ui.lerpDouble(behindSize, full, p)!;
          baseY = ui.lerpDouble(behindBaseY, surface.surfaceY, p)!;
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
          s *= pose.scale;
          baseY -= pose.rise;
          opacity = pose.opacity;
        }

        final lift = ((surface.surfaceY - baseY) / full).clamp(0.0, 1.0);
        if (opacity > 0.05) {
          paintContactShadow(
            canvas,
            cx,
            surface.surfaceY,
            s * (1 - lift * 0.35),
            strength: (1 - lift) * opacity,
          );
        }
        final w = s * (1 + squash);
        final h = s * (1 - squash);
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
            Offset(cx, surface.surfaceY - full * 0.45),
            full * 0.62,
            sellT,
          );
        }
      }

      if (selling) {
        paintSoldStamp(
          canvas,
          Rect.fromLTRB(rect.left, rect.top, rect.right, surface.surfaceY),
          sellT,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrayBeltPainter old) => true;
}
