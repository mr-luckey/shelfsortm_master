import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/audio_service.dart';
import '../widgets/emoji_assets.dart';

/// Full black ASMR mode — scrolling cubbies; sort 3 matching faces to sell.
class AsmrModeScreen extends StatefulWidget {
  const AsmrModeScreen({super.key});

  static const double baseRowHeight = 56;
  static const double colWidth = 150;
  static const int spotsPerCell = 3;

  /// All Fluent emoji types — ASMR picks randomly from this set.
  static List<String> get faces => EmojiAssets.allTypes;

  @override
  State<AsmrModeScreen> createState() => _AsmrModeScreenState();
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
  final _CellKey from;
  final int fromSlot;
  final String emoji;
  Offset finger;

  _HeldFace({
    required this.from,
    required this.fromSlot,
    required this.emoji,
    required this.finger,
  });
}

/// Match-3 sell animation for one cubby (wood door + SOLD stamp).
class _SellAnim {
  final String emoji;
  double t;

  _SellAnim({required this.emoji, this.t = 0});
}

class _AsmrModeScreenState extends State<AsmrModeScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  /// Unbounded scroll distance per row (px).
  final List<double> _scroll = [];

  /// Per-row speeds (px/sec). Sign = direction.
  final List<double> _speeds = [];

  /// Overrides for cells the player has changed. Values are length-3 slot lists.
  final Map<_CellKey, List<String?>> _cells = {};

  /// Boxes the player has interacted with — never auto-mutated until empty/sold.
  final Set<_CellKey> _touched = {};

  /// Active sell animations (wood cover + stamp), then refill.
  final Map<_CellKey, _SellAnim> _selling = {};

  /// Small face pool so matches stay easy (2–3 sells quickly).
  late final List<String> _pool;
  final Map<String, ui.Image> _faceImages = {};

  int _refillNonce = 0;
  int _rowCount = 0;
  ui.Image? _cubbyBg;
  _HeldFace? _held;
  Size _boardSize = Size.zero;
  double _rowHeight = AsmrModeScreen.baseRowHeight;

  /// While holding, world scrolls this much slower.
  static const double _slowMoFactor = 0.35;
  static const double _baseSpeed = 32.0;
  static const double _sellDuration = 0.9;
  static const _cubbyAsset = 'assets/images/premium/cupboards/shelf_cell.png';

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    final faces = List<String>.from(AsmrModeScreen.faces)..shuffle(rng);
    // Random sample from every emoji — keeps matches findable mid-session.
    _pool = faces.take(math.min(24, faces.length)).toList();
    _ticker = createTicker(_onTick)..start();
    _loadCubbyBg();
    _loadFaceImages();
  }

  Future<void> _loadFaceImages() async {
    for (final type in _pool) {
      try {
        final data = await rootBundle.load(EmojiAssets.pathFor(type));
        final codec =
            await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        if (!mounted) {
          frame.image.dispose();
          return;
        }
        _faceImages[type] = frame.image;
      } catch (_) {
        // Missing art — slot stays empty visually.
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadCubbyBg() async {
    final data = await rootBundle.load(_cubbyAsset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() => _cubbyBg = frame.image);
  }

  void _ensureRows(int count) {
    if (count == _rowCount && _speeds.length == count) return;

    while (_scroll.length < count) {
      final i = _scroll.length;
      final brick = (i.isOdd) ? AsmrModeScreen.colWidth / 2 : 0.0;
      _scroll.add(brick);
      _speeds.add(0);
    }
    if (_scroll.length > count) {
      _scroll.removeRange(count, _scroll.length);
      _speeds.removeRange(count, _speeds.length);
    }

    for (var i = 0; i < count; i++) {
      _speeds[i] = i.isEven ? _baseSpeed : -_baseSpeed;
    }
    _rowCount = count;
  }

  /// Easy goods-sort layouts: lots of 2-of-a-kind + empty slots to finish.
  List<String?> _generateEasySlots(int row, int col, {int nonce = 0}) {
    if (_pool.isEmpty) {
      return List<String?>.filled(AsmrModeScreen.spotsPerCell, null);
    }
    final rng = math.Random(_seed(row, col) ^ (nonce * 0x9E3779B9));
    final a = _pool[rng.nextInt(_pool.length)];
    String pickOther(String avoid) {
      for (var i = 0; i < 8; i++) {
        final v = _pool[rng.nextInt(_pool.length)];
        if (v != avoid) return v;
      }
      return _pool.firstWhere((e) => e != avoid, orElse: () => avoid);
    }

    final b = pickOther(a);
    var c = pickOther(a);
    if (c == b && _pool.length > 2) {
      c = _pool.firstWhere((e) => e != a && e != b, orElse: () => c);
    }

    final roll = rng.nextDouble();
    final List<String?> raw;
    if (roll < 0.48) {
      // One emoji away from a sell.
      raw = [a, a, null];
    } else if (roll < 0.72) {
      // Move the odd one out, then sell.
      raw = [a, a, b];
    } else if (roll < 0.88) {
      raw = [a, null, null];
    } else if (roll < 0.96) {
      raw = [a, b, null];
    } else {
      raw = [a, b, c];
    }

    // Pack filled slots left so free spots stay at the end (buffer).
    final filled = raw.whereType<String>().toList();
    final slots = List<String?>.filled(AsmrModeScreen.spotsPerCell, null);
    for (var i = 0; i < filled.length && i < slots.length; i++) {
      slots[i] = filled[i];
    }
    return slots;
  }

  int _seed(int row, int col) => Object.hash(row, col, 0xA5E17);

  List<String?> _slotsFor(_CellKey key) {
    final existing = _cells[key];
    if (existing != null) return existing;
    // Never overwrite a player-touched box (those stay in `_cells`).
    final generated = _generateEasySlots(key.row, key.col);
    _cells[key] = generated;
    return generated;
  }

  bool _isSelling(_CellKey key) => _selling.containsKey(key);

  bool _isMatch3(List<String?> slots) {
    if (slots.length < AsmrModeScreen.spotsPerCell) return false;
    if (slots.any((s) => s == null)) return false;
    final first = slots.first;
    return slots.every((s) => s == first);
  }

  void _markTouched(_CellKey key) => _touched.add(key);

  void _tryStartSell(_CellKey key) {
    if (_isSelling(key)) return;
    final slots = _cells[key];
    if (slots == null || !_isMatch3(slots)) return;
    _selling[key] = _SellAnim(emoji: slots.first!);
    HapticFeedback.mediumImpact();
  }

  void _finishSell(_CellKey key) {
    _refillNonce += 1;
    // Sold box leaves; a fresh easy box arrives in its place.
    _cells[key] = _generateEasySlots(key.row, key.col, nonce: _refillNonce);
    _touched.remove(key);
  }

  void _onTick(Duration elapsed) {
    if (_last == Duration.zero) {
      _last = elapsed;
      return;
    }
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0 || dt > 0.1 || _rowCount == 0) return;

    final scale = _held != null ? _slowMoFactor : 1.0;
    for (var i = 0; i < _rowCount; i++) {
      _scroll[i] += _speeds[i] * dt * scale;
    }

    if (_selling.isNotEmpty) {
      final done = <_CellKey>[];
      for (final e in _selling.entries) {
        e.value.t += dt / _sellDuration;
        if (e.value.t >= 1.0) done.add(e.key);
      }
      for (final key in done) {
        _selling.remove(key);
        _finishSell(key);
      }
    }

    setState(() {});
  }

  _Hit? _hitTest(Offset local) {
    if (_boardSize == Size.zero || _rowHeight <= 0) return null;
    final row = (local.dy / _rowHeight).floor();
    if (row < 0 || row >= _rowCount) return null;

    final ox = row < _scroll.length ? _scroll[row] : 0.0;
    final col = ((local.dx - ox) / AsmrModeScreen.colWidth).floor();
    final cellLeft = col * AsmrModeScreen.colWidth + ox;
    final localX = local.dx - cellLeft;
    if (localX < 0 || localX > AsmrModeScreen.colWidth) return null;

    final key = _CellKey(row, col);
    if (_isSelling(key)) return null;

    final slots = _slotsFor(key);
    final totalW = AsmrModeScreen.colWidth * 0.88;
    final slotW = totalW / AsmrModeScreen.spotsPerCell;
    final startX = (AsmrModeScreen.colWidth - totalW) / 2;
    final slot = ((localX - startX) / slotW).floor().clamp(
      0,
      AsmrModeScreen.spotsPerCell - 1,
    );

    return _Hit(key: key, slot: slot, slots: slots);
  }

  void _onPointerDown(Offset local) {
    if (_held != null) return;
    final hit = _hitTest(local);
    if (hit == null) return;
    final emoji = hit.slots[hit.slot];
    if (emoji == null) return;

    hit.slots[hit.slot] = null;
    _markTouched(hit.key);
    HapticFeedback.selectionClick();
    setState(() {
      _held = _HeldFace(
        from: hit.key,
        fromSlot: hit.slot,
        emoji: emoji,
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

    final hit = _hitTest(local);
    var placed = false;
    _CellKey? placedKey;

    if (hit != null) {
      // Prefer the exact free slot under the finger; else first free spot.
      var dest = hit.slots[hit.slot] == null ? hit.slot : -1;
      if (dest < 0) dest = hit.slots.indexWhere((s) => s == null);
      if (dest >= 0) {
        hit.slots[dest] = held.emoji;
        placed = true;
        placedKey = hit.key;
        _markTouched(hit.key);
        HapticFeedback.lightImpact();
      }
    }

    if (!placed) {
      final origin = _slotsFor(held.from);
      if (origin[held.fromSlot] == null) {
        origin[held.fromSlot] = held.emoji;
      } else {
        final free = origin.indexWhere((s) => s == null);
        if (free >= 0) {
          origin[free] = held.emoji;
        } else {
          origin[held.fromSlot] = held.emoji;
        }
      }
      placedKey = held.from;
      _markTouched(held.from);
    }

    if (placedKey != null) _tryStartSell(placedKey);

    setState(() => _held = null);
  }

  void _onPointerCancel() {
    final held = _held;
    if (held == null) return;
    final origin = _slotsFor(held.from);
    if (origin[held.fromSlot] == null) {
      origin[held.fromSlot] = held.emoji;
    } else {
      final free = origin.indexWhere((s) => s == null);
      if (free >= 0) origin[free] = held.emoji;
    }
    _markTouched(held.from);
    _tryStartSell(held.from);
    setState(() => _held = null);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _cubbyBg?.dispose();
    for (final img in _faceImages.values) {
      img.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sidePad = 16.0;
    const cardRadius = 20.0;
    final held = _held;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.black,
        systemNavigationBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(sidePad, 48, sidePad, 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(cardRadius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(cardRadius),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final naturalRows =
                            (constraints.maxHeight /
                                    AsmrModeScreen.baseRowHeight)
                                .ceil();
                        final rows = math.max(3, naturalRows - 2);
                        final rowHeight = constraints.maxHeight / rows;
                        _ensureRows(rows);
                        _boardSize = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        _rowHeight = rowHeight;

                        // Snapshot visible cells for painter.
                        final visible = <_CellKey, List<String?>>{};
                        final sellSnapshot = <_CellKey, _SellAnim>{};
                        for (var r = 0; r < rows; r++) {
                          final ox = r < _scroll.length ? _scroll[r] : 0.0;
                          final kMin =
                              ((-AsmrModeScreen.colWidth - ox) /
                                      AsmrModeScreen.colWidth)
                                  .floor() -
                              1;
                          final kMax =
                              ((constraints.maxWidth - ox) /
                                      AsmrModeScreen.colWidth)
                                  .ceil() +
                              1;
                          for (var k = kMin; k <= kMax; k++) {
                            final key = _CellKey(r, k);
                            visible[key] = List<String?>.from(_slotsFor(key));
                            final sell = _selling[key];
                            if (sell != null) {
                              sellSnapshot[key] = _SellAnim(
                                emoji: sell.emoji,
                                t: sell.t,
                              );
                            }
                          }
                        }

                        return Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (e) => _onPointerDown(e.localPosition),
                          onPointerMove: (e) => _onPointerMove(e.localPosition),
                          onPointerUp: (e) => _onPointerUp(e.localPosition),
                          onPointerCancel: (_) => _onPointerCancel(),
                          child: CustomPaint(
                            size: _boardSize,
                            painter: _AsmrMovingGridPainter(
                              rowHeight: rowHeight,
                              colWidth: AsmrModeScreen.colWidth,
                              scroll: List<double>.from(_scroll),
                              cells: visible,
                              selling: sellSnapshot,
                              cubbyBg: _cubbyBg,
                              faceImages: _faceImages,
                              held: held == null
                                  ? null
                                  : (emoji: held.emoji, finger: held.finger),
                              highlightFree: held != null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: () {
                    context.read<AudioService>().playButton();
                    Navigator.of(context).pop();
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xEE2A1608),
                    side: const BorderSide(color: Color(0xFFB8860B), width: 1.4),
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFF7E6C8),
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hit {
  final _CellKey key;
  final int slot;
  final List<String?> slots;

  const _Hit({required this.key, required this.slot, required this.slots});
}

class _AsmrMovingGridPainter extends CustomPainter {
  final double rowHeight;
  final double colWidth;
  final List<double> scroll;
  final Map<_CellKey, List<String?>> cells;
  final Map<_CellKey, _SellAnim> selling;
  final ui.Image? cubbyBg;
  final Map<String, ui.Image> faceImages;
  final ({String emoji, Offset finger})? held;
  final bool highlightFree;

  const _AsmrMovingGridPainter({
    required this.rowHeight,
    required this.colWidth,
    required this.scroll,
    required this.cells,
    this.selling = const {},
    this.cubbyBg,
    this.faceImages = const {},
    this.held,
    this.highlightFree = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rows = (size.height / rowHeight).ceil();
    final bg = cubbyBg;

    for (var r = 0; r < rows; r++) {
      final top = r * rowHeight;
      final h = math.min(rowHeight, size.height - top);
      if (h <= 0) break;

      final ox = r < scroll.length ? scroll[r] : (r.isOdd ? colWidth / 2 : 0.0);

      final kMin = ((-colWidth - ox) / colWidth).floor() - 1;
      final kMax = ((size.width - ox) / colWidth).ceil() + 1;

      for (var k = kMin; k <= kMax; k++) {
        final left = k * colWidth + ox;
        if (left > size.width || left + colWidth < 0) continue;

        final rect = Rect.fromLTWH(left, top, colWidth, h);
        if (bg != null) {
          paintImage(
            canvas: canvas,
            rect: rect,
            image: bg,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          );
        }

        final key = _CellKey(r, k);
        final sell = selling[key];
        final slots =
            cells[key] ??
            List<String?>.filled(AsmrModeScreen.spotsPerCell, null);

        if (highlightFree && sell == null) {
          final free = slots.where((s) => s == null).length;
          if (free > 0) {
            final glow = Paint()
              ..color = const Color(0x3366BB6A)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2;
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                rect.deflate(3),
                const Radius.circular(8),
              ),
              glow,
            );
          }
        }

        if (sell == null) {
          _paintSlots(canvas, rect, slots);
        } else {
          // Keep faces briefly under closing wood, then cover fully.
          if (sell.t < 0.45) _paintSlots(canvas, rect, slots);
          _paintSoldOverlay(canvas, rect, sell);
        }
      }
    }

    final h = held;
    if (h != null) {
      final side = math.min(rowHeight * 0.72, 42.0);
      _paintFace(
        canvas,
        h.emoji,
        Rect.fromCenter(center: h.finger, width: side, height: side),
      );
    }
  }

  void _paintSoldOverlay(Canvas canvas, Rect rect, _SellAnim sell) {
    final t = sell.t.clamp(0.0, 1.0);
    final doorT = (t / 0.38).clamp(0.0, 1.0);
    final doorH = rect.height * Curves.easeInOutCubic.transform(doorT);
    final doorRect = Rect.fromLTWH(rect.left, rect.top, rect.width, doorH);

    final wood = Paint()
      ..shader = ui.Gradient.linear(
        doorRect.topLeft,
        doorRect.bottomRight,
        const [
          Color(0xFFE8C9A0),
          Color(0xFFD4A574),
          Color(0xFF8B5A2B),
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(doorRect.deflate(2), const Radius.circular(6)),
      wood,
    );

    // Wood grain lines.
    if (doorH > 8) {
      final grain = Paint()
        ..color = const Color(0x338B5A2B)
        ..strokeWidth = 1;
      for (var i = 1; i <= 3; i++) {
        final y = doorRect.top + doorH * (i / 4);
        canvas.drawLine(
          Offset(doorRect.left + 8, y),
          Offset(doorRect.right - 8, y),
          grain,
        );
      }
    }

    // Stamp effect after door mostly closed.
    if (t < 0.32) return;
    final stampT = ((t - 0.32) / 0.28).clamp(0.0, 1.0);
    final bounce = Curves.elasticOut.transform(stampT);
    final scale = 2.2 - 1.2 * bounce;
    final opacity = (stampT * 1.4).clamp(0.0, 1.0);
    // Fade out near the end as the sold box leaves.
    final leave = t > 0.78 ? (1.0 - ((t - 0.78) / 0.22).clamp(0.0, 1.0)) : 1.0;

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
          color: Color.fromRGBO(180, 30, 30, opacity * leave),
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
        ..color = Color.fromRGBO(180, 30, 30, 0.18 * opacity * leave)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      stampRect,
      Paint()
        ..color = Color.fromRGBO(180, 30, 30, 0.85 * opacity * leave)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    stampTp.paint(
      canvas,
      Offset(-stampTp.width / 2, -stampTp.height / 2),
    );
    canvas.restore();
  }

  void _paintSlots(Canvas canvas, Rect rect, List<String?> slots) {
    final side = math.min(rect.height * 0.58, 34.0);
    final totalW = rect.width * 0.88;
    final slotW = totalW / AsmrModeScreen.spotsPerCell;
    final startX = rect.center.dx - totalW / 2;

    for (var i = 0; i < slots.length; i++) {
      final emoji = slots[i];
      if (emoji == null) continue;

      final cx = startX + slotW * (i + 0.5);
      final dest = Rect.fromCenter(
        center: Offset(cx, rect.center.dy),
        width: side,
        height: side,
      );
      _paintFace(canvas, emoji, dest);
    }
  }

  void _paintFace(Canvas canvas, String type, Rect dest) {
    final img = faceImages[type];
    if (img == null) return;
    paintImage(
      canvas: canvas,
      rect: dest,
      image: img,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _AsmrMovingGridPainter old) {
    if (old.rowHeight != rowHeight || old.colWidth != colWidth) return true;
    if (old.cubbyBg != cubbyBg) return true;
    if (old.faceImages != faceImages) return true;
    if (old.highlightFree != highlightFree) return true;
    if (old.held?.emoji != held?.emoji || old.held?.finger != held?.finger) {
      return true;
    }
    if (old.scroll.length != scroll.length) return true;
    for (var i = 0; i < scroll.length; i++) {
      if (old.scroll[i] != scroll[i]) return true;
    }
    if (old.selling.length != selling.length) return true;
    for (final e in selling.entries) {
      final o = old.selling[e.key];
      if (o == null || o.emoji != e.value.emoji || o.t != e.value.t) {
        return true;
      }
    }
    if (old.cells.length != cells.length) return true;
    for (final e in cells.entries) {
      final o = old.cells[e.key];
      if (o == null || o.length != e.value.length) return true;
      for (var i = 0; i < e.value.length; i++) {
        if (o[i] != e.value[i]) return true;
      }
    }
    return false;
  }
}
