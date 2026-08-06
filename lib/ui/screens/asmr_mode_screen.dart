import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/asmr_cubit.dart';
import '../../engine/level_generator.dart';
import '../../services/audio_service.dart';
import '../meta/praise_burst.dart';
import '../premium/premium_goods_fx.dart';
import '../premium/premium_tray_plank.dart';
import '../widgets/emoji_assets.dart';

/// Dual ASMR: scrolling match-3 boxes + top goal trays (gameplay-style planks).
class AsmrModeScreen extends StatefulWidget {
  const AsmrModeScreen({super.key});

  static const double baseRowHeight = 58;
  static const double colWidth = 150; // fallback; live width is responsive
  static const int spotsPerCell = 3;
  static const int plateCount = 3;
  static const double plateBandHeight = 110;
  static const int minBoxesPerRow = 5;
  static const int maxBoxesPerRow = 6;

  /// Same stock as gameplay — flat-base shelf products only.
  static List<String> get faces => LevelGenerator.productTypes;

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
  final _CellKey? from;
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

class _SellAnim {
  final String emoji;
  double t;
  _SellAnim({required this.emoji, this.t = 0});
}

class _Plate {
  String target;
  final List<String?> slots;
  double burstT;
  bool bursting;

  _Plate({required this.target})
      : slots = List<String?>.filled(AsmrModeScreen.spotsPerCell, null),
        burstT = 0,
        bursting = false;

  bool get isFullMatch {
    if (slots.any((s) => s == null)) return false;
    return slots.every((s) => s == target);
  }

  int get filled => slots.whereType<String>().length;
}

class _AsmrModeScreenState extends State<AsmrModeScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final AsmrCubit _cubit;
  Duration _last = Duration.zero;

  /// Painters listen to this — never rebuild the widget tree at 60fps.
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  final List<double> _scroll = [];
  final List<double> _speeds = [];
  final Map<_CellKey, List<String?>> _cells = {};
  final Set<_CellKey> _touched = {};
  final Map<_CellKey, _SellAnim> _selling = {};

  late final List<String> _pool;
  late final List<_Plate> _plates;
  final Map<String, ui.Image> _faceImages = {};
  final List<String> _bag = [];

  int _refillNonce = 0;
  int _rowCount = 0;
  int _boxesPerRow = AsmrModeScreen.maxBoxesPerRow;
  double _colWidth = AsmrModeScreen.colWidth;
  int _plateClears = 0;
  int _boxClears = 0;
  ui.Image? _cubbyBg;
  _HeldFace? _held;
  Size _boardSize = Size.zero;
  double _rowHeight = AsmrModeScreen.baseRowHeight;

  static const double _baseSpeed = 44.0;
  static const double _sellDuration = 0.85;
  static const double _burstDuration = 0.5;
  static const double _dropSnapRadius = 92.0;
  static const _cubbyAsset = 'assets/images/premium/cupboards/shelf_cell.png';

  static const _accentColors = <Color>[
    Color(0xFFE8C45A),
    Color(0xFF6BCBFF),
    Color(0xFFFF6B9D),
    Color(0xFF6BFFB8),
  ];

  void _repaint() => _frame.value++;

  void _syncScores() =>
      _cubit.setScores(boxes: _boxClears, plates: _plateClears);

  @override
  void initState() {
    super.initState();
    _cubit = AsmrCubit();
    final rng = math.Random();
    final faces = List<String>.from(AsmrModeScreen.faces)..shuffle(rng);
    _pool = faces;
    _plates = [
      for (var i = 0; i < AsmrModeScreen.plateCount; i++)
        _Plate(target: _pool[i % _pool.length]),
    ];
    _dedupePlateTargets();
    _refillBag(forceTargets: true);
    _ticker = createTicker(_onTick)..start();
    _loadCubbyBg();
    _loadFaceImages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audio = context.read<AudioService>();
      audio.asmrMode = true;
      audio.startMusic();
      for (var r = 0; r < math.max(_rowCount, 3); r++) {
        for (var c = 0; c < _boxesPerRow; c++) {
          _slotsFor(_CellKey(r, c));
        }
      }
      _ensureMinMatchOnBoard();
      _repaint();
    });
  }

  void _dedupePlateTargets() {
    final used = <String>{};
    final rng = math.Random();
    for (final p in _plates) {
      if (!used.contains(p.target)) {
        used.add(p.target);
        continue;
      }
      final next = _pool.firstWhere(
        (e) => !used.contains(e),
        orElse: () => _pool[rng.nextInt(_pool.length)],
      );
      p.target = next;
      used.add(next);
    }
  }

  Set<String> get _plateTargets => {for (final p in _plates) p.target};

  Color _tintFor(String type) =>
      _accentColors[type.hashCode.abs() % _accentColors.length];

  void _refillBag({bool forceTargets = false}) {
    final rng = math.Random();
    // Scrambled complete triplets so every type can finish a box of 3.
    for (var i = 0; i < 10; i++) {
      final type = _pool[rng.nextInt(_pool.length)];
      _bag.addAll([type, type, type]);
    }
    if (forceTargets) {
      for (final t in _plateTargets) {
        _bag.addAll([t, t, t]);
      }
    }
    _bag.shuffle(rng);
  }

  String _takeFromBag({String? prefer}) {
    if (_bag.length < 6) _refillBag();
    if (prefer != null) {
      final i = _bag.indexOf(prefer);
      if (i >= 0) return _bag.removeAt(i);
    }
    return _bag.removeLast();
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
      } catch (_) {}
    }
    if (mounted) _repaint();
  }

  Future<void> _loadCubbyBg() async {
    final data = await rootBundle.load(_cubbyAsset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    _cubbyBg = frame.image;
    _repaint();
  }

  void _ensureRows(int count) {
    if (count == _rowCount && _speeds.length == count) return;
    while (_scroll.length < count) {
      final i = _scroll.length;
      _scroll.add(i.isOdd ? AsmrModeScreen.colWidth / 2 : 0.0);
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

  int _wrapCol(int col) {
    final n = _boxesPerRow;
    return ((col % n) + n) % n;
  }

  _CellKey _canon(int row, int col) => _CellKey(row, _wrapCol(col));

  void _layoutBoard(double width, double gridH) {
    _boxesPerRow = width >= 380
        ? AsmrModeScreen.maxBoxesPerRow
        : AsmrModeScreen.minBoxesPerRow;
    // Keep original cubby width — do not squeeze to fit the row.
    _colWidth = AsmrModeScreen.colWidth;
    final naturalRows = (gridH / AsmrModeScreen.baseRowHeight).floor();
    final rows = math.max(3, naturalRows);
    _ensureRows(rows);
    _rowHeight = gridH / rows;
  }

  int _countTypeInBoxes(String type, {_CellKey? ignore}) {
    var n = 0;
    for (final e in _cells.entries) {
      if (ignore != null && e.key == ignore) continue;
      for (final s in e.value) {
        if (s == type) n++;
      }
    }
    if (_held != null && _held!.emoji == type) n++;
    return n;
  }

  /// At most 3 of one type on the looping board.
  static const int _maxSameOnScreen = 3;

  /// Never-empty box: 3 products usually, sometimes 2.
  List<String?> _generateEasySlots(int row, int col, {int nonce = 0}) {
    final rng = math.Random(_seed(row, col) ^ (nonce * 0x9E3779B9));
    final want = rng.nextDouble() < 0.78 ? 3 : 2;
    final slots = List<String?>.filled(AsmrModeScreen.spotsPerCell, null);
    for (var i = 0; i < want; i++) {
      slots[i] = _pickType(rng);
    }
    // Absolute guarantee — never return an empty cubby.
    if (slots.every((s) => s == null)) {
      final a = _pool[rng.nextInt(_pool.length)];
      slots[0] = a;
      slots[1] = a;
      slots[2] = rng.nextDouble() < 0.5 ? a : _pool[rng.nextInt(_pool.length)];
    }
    _breakAutoShelfTriple(slots, rng);
    return slots;
  }

  void _breakAutoShelfTriple(List<String?> slots, math.Random rng) {
    if (!_isMatch3(slots)) return;
    final trip = slots.first!;
    for (var i = 0; i < 10; i++) {
      final alt = _pool[rng.nextInt(_pool.length)];
      if (alt == trip) continue;
      slots[rng.nextInt(AsmrModeScreen.spotsPerCell)] = alt;
      return;
    }
    slots[2] = _pool.firstWhere((e) => e != trip, orElse: () => trip);
  }

  String _pickType(math.Random rng) {
    // Prefer types still under the on-screen cap.
    for (var i = 0; i < 20; i++) {
      final t = _takeFromBag(
        prefer: i < 3 && _plateTargets.isNotEmpty
            ? _plateTargets.elementAt(rng.nextInt(_plateTargets.length))
            : null,
      );
      if (_countTypeInBoxes(t) < _maxSameOnScreen) return t;
    }
    return _pool[rng.nextInt(_pool.length)];
  }

  bool _boardHasCompletableTriple() {
    final counts = <String, int>{};
    for (final slots in _cells.values) {
      for (final s in slots) {
        if (s == null) continue;
        counts[s] = (counts[s] ?? 0) + 1;
        if (counts[s]! >= 3) return true;
      }
    }
    if (_held != null) {
      final c = (counts[_held!.emoji] ?? 0) + 1;
      if (c >= 3) return true;
    }
    // Ready-made match-3 box also counts.
    for (final slots in _cells.values) {
      if (_isMatch3(slots)) return true;
    }
    return false;
  }

  /// Keep at least one 3-of-a-kind available so the player never waits.
  /// Also keep each tray goal visible somewhere on the looping board.
  void _ensureMinMatchOnBoard() {
    if (_pool.isEmpty) return;
    final rng = math.Random();

    for (final need in _plateTargets) {
      if (_countTypeInBoxes(need) > 0) continue;
      final keys = [
        for (var r = 0; r < _rowCount; r++)
          for (var c = 0; c < _boxesPerRow; c++) _CellKey(r, c),
      ]..shuffle(rng);
      for (final key in keys) {
        if (_isSelling(key)) continue;
        final slots = _cells.putIfAbsent(
          key,
          () => _generateEasySlots(key.row, key.col),
        );
        final dest = slots.indexWhere((s) => s == null) >= 0
            ? slots.indexWhere((s) => s == null)
            : 0;
        slots[dest] = need;
        break;
      }
    }

    if (_boardHasCompletableTriple()) return;

    final type = _plateTargets.isNotEmpty && rng.nextBool()
        ? _plateTargets.elementAt(rng.nextInt(_plateTargets.length))
        : _pool[rng.nextInt(_pool.length)];

    var need = 3 - _countTypeInBoxes(type);
    if (need <= 0) return;

    final keys = [
      for (var r = 0; r < _rowCount; r++)
        for (var c = 0; c < _boxesPerRow; c++) _CellKey(r, c),
    ]..shuffle(rng);

    for (final key in keys) {
      if (need <= 0) break;
      final slots = _cells[key] ?? _generateEasySlots(key.row, key.col);
      _cells[key] = slots;
      if (_isSelling(key)) continue;

      var dest = slots.indexWhere((s) => s == null);
      if (dest < 0) {
        dest = slots.indexWhere((s) => s != null && s != type);
      }
      if (dest < 0) continue;
      slots[dest] = type;
      need--;
    }

    if (!_boardHasCompletableTriple()) {
      final keys = [
        for (var r = 0; r < _rowCount; r++)
          for (var c = 0; c < _boxesPerRow; c++) _CellKey(r, c),
      ]..shuffle(rng);
      var placed = 0;
      for (final key in keys) {
        if (placed >= 3) break;
        final slots = _cells[key] ?? _generateEasySlots(key.row, key.col);
        _cells[key] = slots;
        var dest = slots.indexWhere((s) => s == null);
        if (dest < 0) dest = rng.nextInt(AsmrModeScreen.spotsPerCell);
        slots[dest] = type;
        _breakAutoShelfTriple(slots, rng);
        placed++;
      }
    }
  }

  int _seed(int row, int col) => Object.hash(row, col, 0xA5E17);

  List<String?> _slotsFor(_CellKey key) {
    final canon = _canon(key.row, key.col);
    final existing = _cells[canon];
    if (existing != null) {
      // Repair any empty box that slipped through.
      if (existing.every((s) => s == null)) {
        _cells[canon] = _generateEasySlots(canon.row, canon.col,
            nonce: ++_refillNonce);
        return _cells[canon]!;
      }
      return existing;
    }
    final generated = _generateEasySlots(canon.row, canon.col);
    _cells[canon] = generated;
    return generated;
  }

  bool _isSelling(_CellKey key) =>
      _selling.containsKey(_canon(key.row, key.col));

  bool _isMatch3(List<String?> slots) {
    if (slots.length < AsmrModeScreen.spotsPerCell) return false;
    if (slots.any((s) => s == null)) return false;
    final first = slots.first;
    return slots.every((s) => s == first);
  }

  Future<void> _celebrate({bool plate = false}) async {
    if (!mounted) return;
    final audio = context.read<AudioService>();
    if (plate) {
      audio.playCombo();
    } else {
      audio.playShelfComplete();
    }
    final label = await audio.playPraise();
    if (!mounted) return;
    _cubit.showPraise(label);
    _syncScores();
    _repaint();
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) _cubit.clearPraise();
    });
  }

  void _markTouched(_CellKey key) => _touched.add(_canon(key.row, key.col));

  void _tryStartSell(_CellKey key) {
    final canon = _canon(key.row, key.col);
    if (_isSelling(canon)) return;
    final slots = _cells[canon];
    if (slots == null || !_isMatch3(slots)) return;
    _selling[canon] = _SellAnim(emoji: slots.first!);
    _boxClears++;
    HapticFeedback.mediumImpact();
    _celebrate();
  }

  void _finishSell(_CellKey key) {
    final canon = _canon(key.row, key.col);
    _refillNonce += 1;
    _cells[canon] =
        _generateEasySlots(canon.row, canon.col, nonce: _refillNonce);
    _touched.remove(canon);
    _ensureMinMatchOnBoard();
  }

  void _tryBurstPlate(int index) {
    final p = _plates[index];
    if (p.bursting || !p.isFullMatch) return;
    p.bursting = true;
    p.burstT = 0;
    _plateClears++;
    HapticFeedback.heavyImpact();
    _celebrate(plate: true);
  }

  void _finishPlateBurst(int index) {
    final used = {for (final p in _plates) p.target};
    final rng = math.Random();
    // Prefer a type not currently on any tray so goals feel fresh.
    final candidates = _pool.where((e) => !used.contains(e)).toList()
      ..shuffle(rng);
    final next = candidates.isNotEmpty
        ? candidates.first
        : _pool[rng.nextInt(_pool.length)];
    _plates[index] = _Plate(target: next);
    _bag.addAll([next, next, next]);
    _bag.shuffle(rng);
  }

  void _onTick(Duration elapsed) {
    if (_last == Duration.zero) {
      _last = elapsed;
      return;
    }
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0 || dt > 0.1) return;

    if (_rowCount > 0) {
      final scale = _held != null ? 0.0 : 1.0;
      for (var i = 0; i < _rowCount; i++) {
        _scroll[i] += _speeds[i] * dt * scale;
      }
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

    for (var i = 0; i < _plates.length; i++) {
      final p = _plates[i];
      if (!p.bursting) continue;
      p.burstT += dt / _burstDuration;
      if (p.burstT >= 1.0) _finishPlateBurst(i);
    }

    // Paint only — never setState on the animation clock.
    _repaint();
  }

  _Hit? _hitTestBox(Offset local) {
    final gridTop = AsmrModeScreen.plateBandHeight + 8;
    final gridLocal = Offset(local.dx, local.dy - gridTop);
    if (gridLocal.dy < 0) return null;
    if (_boardSize == Size.zero || _rowHeight <= 0 || _colWidth <= 0) {
      return null;
    }
    final row = (gridLocal.dy / _rowHeight).floor();
    if (row < 0 || row >= _rowCount) return null;

    final ox = row < _scroll.length ? _scroll[row] : 0.0;
    final col = ((gridLocal.dx - ox) / _colWidth).floor();
    final cellLeft = col * _colWidth + ox;
    final localX = gridLocal.dx - cellLeft;
    if (localX < 0 || localX > _colWidth) return null;

    final key = _canon(row, col);
    if (_isSelling(key)) return null;

    final slots = _slotsFor(key);
    final totalW = _colWidth * 0.88;
    final slotW = totalW / AsmrModeScreen.spotsPerCell;
    final startX = (_colWidth - totalW) / 2;
    final slot = ((localX - startX) / slotW)
        .floor()
        .clamp(0, AsmrModeScreen.spotsPerCell - 1);

    return _Hit(key: key, slot: slot, slots: slots);
  }

  int? _hitPlateIndex(Offset local) {
    if (local.dy < 0 || local.dy > AsmrModeScreen.plateBandHeight) return null;
    final w = _boardSize.width;
    if (w <= 0) return null;
    const pad = 2.0;
    const gap = 10.0;
    final plateW =
        (w - pad * 2 - gap * (AsmrModeScreen.plateCount - 1)) /
        AsmrModeScreen.plateCount;
    final x = local.dx - pad;
    if (x < 0) return null;
    final lane = plateW + gap;
    final i = (x / lane).floor();
    if (i < 0 || i >= AsmrModeScreen.plateCount) return null;
    final inLane = x - i * lane;
    if (inLane > plateW) return null;
    return i;
  }

  /// Same empty-slot search as gameplay [dropSlot], for ASMR box slots.
  int? _asmrDropSlot(List<String?> slots, int slotIndex) {
    bool free(int i) => i >= 0 && i < slots.length && slots[i] == null;

    if (free(slotIndex)) return slotIndex;
    for (var step = 1; step < slots.length; step++) {
      if (free(slotIndex - step)) return slotIndex - step;
      if (free(slotIndex + step)) return slotIndex + step;
    }
    return null;
  }

  /// Where a released good lands on the scrolling boxes (gameplay-style).
  _Hit? _resolveBoxDrop(Offset local) {
    final hit = _hitTestBox(local);
    if (hit != null) {
      final dest = _asmrDropSlot(hit.slots, hit.slot);
      if (dest != null) {
        return _Hit(key: hit.key, slot: dest, slots: hit.slots);
      }
    }
    return _snapDropHit(local);
  }

  _Hit? _snapDropHit(Offset local) {
    if (_boardSize == Size.zero || _rowCount <= 0 || _colWidth <= 0) return null;
    final gridTop = AsmrModeScreen.plateBandHeight + 8;
    final gridY = local.dy - gridTop;
    if (gridY < 0) return null;

    _Hit? bestNear;
    _Hit? bestAny;
    var bestNearDist2 = _dropSnapRadius * _dropSnapRadius;
    var bestAnyDist2 = double.infinity;
    final totalW = _colWidth * 0.88;
    final slotW = totalW / AsmrModeScreen.spotsPerCell;
    final startX = (_colWidth - totalW) / 2;

    for (var row = 0; row < _rowCount; row++) {
      final top = row * _rowHeight;
      if (gridY < top - _rowHeight || gridY > top + _rowHeight * 2) continue;
      final ox = row < _scroll.length ? _scroll[row] : 0.0;
      final kMin = ((-_colWidth - ox) / _colWidth).floor() - 1;
      final kMax = ((_boardSize.width - ox) / _colWidth).ceil() + 1;
      for (var k = kMin; k <= kMax; k++) {
        final left = k * _colWidth + ox;
        if (left > _boardSize.width || left + _colWidth < 0) continue;
        final key = _canon(row, k);
        if (_isSelling(key)) continue;
        final slots = _slotsFor(key);
        for (var s = 0; s < AsmrModeScreen.spotsPerCell; s++) {
          if (slots[s] != null) continue;
          final cx = left + startX + slotW * (s + 0.5);
          final cy = gridTop + top + _rowHeight * 0.5;
          final dx = local.dx - cx;
          final dy = local.dy - cy;
          final d2 = dx * dx + dy * dy;
          if (d2 < bestAnyDist2) {
            bestAnyDist2 = d2;
            bestAny = _Hit(key: key, slot: s, slots: slots);
          }
          if (d2 < bestNearDist2) {
            bestNearDist2 = d2;
            bestNear = _Hit(key: key, slot: s, slots: slots);
          }
        }
      }
    }
    return bestNear ?? bestAny;
  }

  bool _tryPlaceOnMatchingPlate(_HeldFace held, {int? preferredIndex}) {
    if (preferredIndex != null) {
      final plate = _plates[preferredIndex];
      if (!plate.bursting &&
          held.emoji == plate.target &&
          plate.slots.any((s) => s == null)) {
        final dest = plate.slots.indexWhere((s) => s == null);
        plate.slots[dest] = held.emoji;
        context.read<AudioService>().playPlace();
        _tryBurstPlate(preferredIndex);
        return true;
      }
    }
    for (var i = 0; i < _plates.length; i++) {
      if (i == preferredIndex) continue;
      final p = _plates[i];
      if (p.bursting || held.emoji != p.target) continue;
      final dest = p.slots.indexWhere((s) => s == null);
      if (dest < 0) continue;
      p.slots[dest] = held.emoji;
      context.read<AudioService>().playPlace();
      _tryBurstPlate(i);
      return true;
    }
    return false;
  }

  void _onPointerDown(Offset local) {
    if (_held != null) return;
    // Only pick from moving boxes (not from plates).
    final hit = _hitTestBox(local);
    if (hit == null) return;
    final emoji = hit.slots[hit.slot];
    if (emoji == null) return;

    hit.slots[hit.slot] = null;
    _markTouched(hit.key);
    HapticFeedback.selectionClick();
    context.read<AudioService>().playButton();
    _held = _HeldFace(
      from: hit.key,
      fromSlot: hit.slot,
      emoji: emoji,
      finger: local,
    );
    _repaint();
  }

  void _onPointerMove(Offset local) {
    final held = _held;
    if (held == null) return;
    held.finger = local;
    _repaint();
  }

  void _returnHeldToOrigin(_HeldFace held) {
    if (held.from == null) return;
    final origin = _slotsFor(held.from!);
    final dest = _asmrDropSlot(origin, held.fromSlot) ?? held.fromSlot;
    origin[dest] = held.emoji;
    _markTouched(held.from!);
    _tryStartSell(held.from!);
  }

  void _onPointerUp(Offset local) {
    final held = _held;
    if (held == null) return;

    // Prefer dropping onto a matching plate.
    final plateI = _hitPlateIndex(local);
    if (_tryPlaceOnMatchingPlate(held, preferredIndex: plateI)) {
      _held = null;
      _repaint();
      return;
    }

    // Box sort — same drop rules as premium gameplay shelves.
    final drop = _resolveBoxDrop(local);
    var placed = false;
    _CellKey? placedKey;

    if (drop != null) {
      final sameSpot = held.from == drop.key && held.fromSlot == drop.slot;
      if (!sameSpot) {
        drop.slots[drop.slot] = held.emoji;
        placed = true;
        placedKey = drop.key;
        _markTouched(drop.key);
        HapticFeedback.lightImpact();
        context.read<AudioService>().playPlace();
      }
    }

    if (!placed) {
      _returnHeldToOrigin(held);
      placedKey = held.from;
    } else if (placedKey != null) {
      _tryStartSell(placedKey);
    }

    _held = null;
    _syncScores();
    _repaint();
  }

  void _onPointerCancel() {
    final held = _held;
    if (held == null) return;
    _returnHeldToOrigin(held);
    _held = null;
    _repaint();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    _cubit.close();
    _cubbyBg?.dispose();
    for (final img in _faceImages.values) {
      img.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sidePad = 12.0;

    return BlocProvider<AsmrCubit>.value(
      value: _cubit,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.black,
          systemNavigationBarColor: Colors.black,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const RepaintBoundary(child: _AsmrBackdrop()),
              SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(sidePad, 44, sidePad, 12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          _boardSize = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          final gridH = math.max(
                            120.0,
                            constraints.maxHeight -
                                AsmrModeScreen.plateBandHeight -
                                8,
                          );
                          _layoutBoard(constraints.maxWidth, gridH);
                          for (var r = 0; r < _rowCount; r++) {
                            for (var c = 0; c < _boxesPerRow; c++) {
                              _slotsFor(_CellKey(r, c));
                            }
                          }

                          return Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (e) =>
                                _onPointerDown(e.localPosition),
                            onPointerMove: (e) =>
                                _onPointerMove(e.localPosition),
                            onPointerUp: (e) => _onPointerUp(e.localPosition),
                            onPointerCancel: (_) => _onPointerCancel(),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: AsmrModeScreen.plateBandHeight,
                                  width: constraints.maxWidth,
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: _AsmrPlatesPainter(
                                        plates: _plates,
                                        faceImages: _faceImages,
                                        tintFor: _tintFor,
                                        heldTypeOf: () => _held?.emoji,
                                        repaint: _frame,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: const Color(0xBB141414),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.12),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: RepaintBoundary(
                                        child: CustomPaint(
                                          size: Size(
                                            constraints.maxWidth,
                                            gridH,
                                          ),
                                          painter: _AsmrMovingGridPainter(
                                            rowHeight: _rowHeight,
                                            colWidth: _colWidth,
                                            boxesPerRow: _boxesPerRow,
                                            scroll: _scroll,
                                            cells: _cells,
                                            selling: _selling,
                                            cubbyBgOf: () => _cubbyBg,
                                            faceImages: _faceImages,
                                            plateTargets: _plateTargets,
                                            tintFor: _tintFor,
                                            repaint: _frame,
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
                      ),
                    ),
                    IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _HeldOverlayPainter(
                            faceImages: _faceImages,
                            heldOf: () => _held,
                            repaint: _frame,
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
                          context.read<AudioService>().asmrMode = false;
                          context.read<AudioService>().playButton();
                          Navigator.of(context).pop();
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xEE2A1608),
                          side: const BorderSide(
                            color: Color(0xFFB8860B),
                            width: 1.4,
                          ),
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFF7E6C8),
                          size: 26,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 12,
                      child: BlocBuilder<AsmrCubit, AsmrState>(
                        buildWhen: (p, c) =>
                            p.boxClears != c.boxClears ||
                            p.plateClears != c.plateClears,
                        builder: (context, state) {
                          return Row(
                            children: [
                              _ScoreChip(
                                label: 'Trays',
                                value: state.plateClears,
                              ),
                              const SizedBox(width: 8),
                              _ScoreChip(
                                label: 'Boxes',
                                value: state.boxClears,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    BlocBuilder<AsmrCubit, AsmrState>(
                      buildWhen: (p, c) =>
                          p.praise != c.praise ||
                          p.praiseSeq != c.praiseSeq,
                      builder: (context, state) {
                        if (state.praise == null) {
                          return const SizedBox.shrink();
                        }
                        return PraiseBurst(
                          key: ValueKey(state.praiseSeq),
                          label: state.praise!,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AsmrBackdrop extends StatelessWidget {
  const _AsmrBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/rooms/premium_room_bg.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Image.asset(
            'assets/images/rooms/gameplay_room_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                const ColoredBox(color: Color(0xFF1A1208)),
          ),
        ),
        const ColoredBox(color: Color(0x66000000)),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final int value;
  const _ScoreChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xEE2A1608),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB8860B), width: 1.2),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: Color(0xFFF7E6C8),
          fontWeight: FontWeight.w800,
          fontSize: 12,
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

class _HeldOverlayPainter extends CustomPainter {
  final Map<String, ui.Image> faceImages;
  final _HeldFace? Function() heldOf;

  _HeldOverlayPainter({
    required this.faceImages,
    required this.heldOf,
    Listenable? repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final held = heldOf();
    if (held == null) return;
    final img = faceImages[held.emoji];
    if (img == null) return;
    const side = 48.0;
    paintImage(
      canvas: canvas,
      rect: Rect.fromCenter(center: held.finger, width: side, height: side),
      image: img,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _HeldOverlayPainter old) => false;
}

class _AsmrPlatesPainter extends CustomPainter {
  final List<_Plate> plates;
  final Map<String, ui.Image> faceImages;
  final Color Function(String) tintFor;
  final String? Function() heldTypeOf;

  _AsmrPlatesPainter({
    required this.plates,
    required this.faceImages,
    required this.tintFor,
    required this.heldTypeOf,
    Listenable? repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 2.0;
    const gap = 10.0;
    final n = plates.length;
    final trayW = (size.width - pad * 2 - gap * (n - 1)) / n;
    final trayH = size.height;

    for (var i = 0; i < n; i++) {
      final p = plates[i];
      final left = pad + i * (trayW + gap);
      final rect = Rect.fromLTWH(left, 0, trayW, trayH);
      final tint = tintFor(p.target);

      canvas.save();
      if (p.bursting) {
        final t = p.burstT.clamp(0.0, 1.0);
        final s = 1.0 + 0.28 * Curves.easeOut.transform(t);
        canvas.translate(rect.center.dx, rect.center.dy);
        canvas.scale(s, s * (1.0 - 0.5 * t));
        canvas.translate(-rect.center.dx, -rect.center.dy);
      }

      // Same wooden tray plank as gameplay belt.
      final surface = paintTrayPlank(canvas, rect);

      final heldType = heldTypeOf();
      if (heldType == p.target && !p.bursting) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              surface.left - 2,
              surface.surfaceY - trayH * 0.62,
              surface.width + 4,
              trayH * 0.7,
            ),
            const Radius.circular(10),
          ),
          Paint()
            ..color = tint.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
      }

      final slotW = surface.width / AsmrModeScreen.spotsPerCell;
      // Large faces so tray goals are obvious.
      final full = math.min(trayH * 0.92, slotW * 1.18);
      final behindSize = full * 0.96;

      for (var s = 0; s < AsmrModeScreen.spotsPerCell; s++) {
        final cx = surface.left + slotW * (s + 0.5);
        final filled = p.slots[s];
        if (filled != null) {
          final dest = Rect.fromCenter(
            center: Offset(cx, surface.surfaceY - full * 0.52),
            width: full,
            height: full,
          );
          _paintFace(canvas, filled, dest, shaded: false);
        } else if (!p.bursting) {
          final dest = Rect.fromCenter(
            center: Offset(cx, surface.surfaceY - behindSize * 0.5),
            width: behindSize,
            height: behindSize,
          );
          _paintFace(canvas, p.target, dest, shaded: true);
        }
      }
      canvas.restore();
    }
  }

  void _paintFace(
    Canvas canvas,
    String type,
    Rect dest, {
    required bool shaded,
  }) {
    final img = faceImages[type];
    if (img == null) {
      canvas.drawCircle(
        dest.center,
        dest.shortestSide * 0.4,
        Paint()
          ..color = Colors.white.withValues(alpha: shaded ? 0.25 : 0.5),
      );
      return;
    }
    paintImage(
      canvas: canvas,
      rect: dest,
      image: img,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      colorFilter: shaded ? shadeFilter(darken: behindShade) : null,
    );
  }

  @override
  bool shouldRepaint(covariant _AsmrPlatesPainter old) => false;
}

class _AsmrMovingGridPainter extends CustomPainter {
  final double rowHeight;
  final double colWidth;
  final int boxesPerRow;
  final List<double> scroll;
  final Map<_CellKey, List<String?>> cells;
  final Map<_CellKey, _SellAnim> selling;
  final ui.Image? Function() cubbyBgOf;
  final Map<String, ui.Image> faceImages;
  final Set<String> plateTargets;
  final Color Function(String) tintFor;

  _AsmrMovingGridPainter({
    required this.rowHeight,
    required this.colWidth,
    required this.boxesPerRow,
    required this.scroll,
    required this.cells,
    this.selling = const {},
    required this.cubbyBgOf,
    this.faceImages = const {},
    this.plateTargets = const {},
    required this.tintFor,
    Listenable? repaint,
  }) : super(repaint: repaint);

  int _wrap(int col) {
    final n = boxesPerRow;
    return ((col % n) + n) % n;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rows = (size.height / rowHeight).ceil();
    final bg = cubbyBgOf();

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

        final key = _CellKey(r, _wrap(k));
        final sell = selling[key];
        final slots = cells[key] ??
            List<String?>.filled(AsmrModeScreen.spotsPerCell, null);

        // Glow boxes that hold a plate-target item.
        final hasTarget = slots.any((s) => s != null && plateTargets.contains(s));
        if (hasTarget && sell == null) {
          final target = slots.firstWhere(
            (s) => s != null && plateTargets.contains(s),
          )!;
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
            Paint()
              ..color = tintFor(target).withValues(alpha: 0.28)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2,
          );
        }

        if (sell == null) {
          _paintSlots(canvas, rect, slots);
        } else {
          if (sell.t < 0.45) _paintSlots(canvas, rect, slots);
          _paintSoldOverlay(canvas, rect, sell);
        }
      }
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
        const [Color(0xFFE8C9A0), Color(0xFFD4A574), Color(0xFF8B5A2B)],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(doorRect.deflate(2), const Radius.circular(6)),
      wood,
    );

    if (t < 0.32) return;
    final stampT = ((t - 0.32) / 0.28).clamp(0.0, 1.0);
    final bounce = Curves.elasticOut.transform(stampT);
    final scale = 2.2 - 1.2 * bounce;
    final opacity = (stampT * 1.4).clamp(0.0, 1.0);
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
    stampTp.paint(canvas, Offset(-stampTp.width / 2, -stampTp.height / 2));
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
      final img = faceImages[emoji];
      if (img == null) continue;
      paintImage(
        canvas: canvas,
        rect: dest,
        image: img,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
      if (plateTargets.contains(emoji)) {
        canvas.drawCircle(
          dest.center,
          dest.shortestSide * 0.55,
          Paint()
            ..color = tintFor(emoji).withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AsmrMovingGridPainter old) => false;
}
