import '../match_engine.dart';
import '../../models/shelf.dart';
import 'level_mechanic.dart';
import 'mechanic_ids.dart';

/// Circular tray that rotates around a pivot (PRD §6A.7).
class RotatingTrayMechanic extends LevelMechanic {
  MatchEngine? _engine;
  int slotCount = 4;
  double speed = 0.4;
  /// 'on_move' | 'on_clear' | 'auto' | 'continuous'
  String rotateMode = 'on_move';
  bool clockwise = true;
  double angle = 0; // radians visual
  int rotationSteps = 0;
  int shelfIndex = -1;
  bool reducedMotion = false;
  double _accum = 0;

  @override
  String get id => MechanicIds.rotatingTray;

  @override
  void initialize(MatchEngine engine, Map<String, dynamic> config) {
    _engine = engine;
    slotCount = config['slotCount'] as int? ?? 4;
    speed = (config['speed'] as num?)?.toDouble() ?? 0.4;
    rotateMode = config['rotateMode'] as String? ?? 'on_move';
    clockwise = config['clockwise'] as bool? ?? true;
    angle = 0;
    rotationSteps = 0;
    _ensureTrayShelf();
  }

  void _ensureTrayShelf() {
    final e = _engine;
    if (e == null) return;
    // Find or create a dock shelf used as rotating tray
    shelfIndex = e.shelves.indexWhere((s) => s.isDock);
    if (shelfIndex < 0) {
      final id =
          e.shelves.map((s) => s.shelfId).fold(0, (a, b) => a > b ? a : b) + 1;
      e.shelves = [
        ...e.shelves,
        Shelf(
          shelfId: id,
          slotCount: slotCount,
          slots: List.generate(slotCount, (_) => const ShelfSlot()),
          isDock: true,
          isTemporary: true,
        ),
      ];
      shelfIndex = e.shelves.length - 1;
    }
  }

  void rotate() {
    final e = _engine;
    if (e == null || shelfIndex < 0 || shelfIndex >= e.shelves.length) return;
    final shelf = e.shelves[shelfIndex];
    final slots = List<ShelfSlot>.from(shelf.slots);
    if (slots.isEmpty) return;
    if (clockwise) {
      final last = slots.removeLast();
      slots.insert(0, last);
    } else {
      final first = slots.removeAt(0);
      slots.add(first);
    }
    e.shelves[shelfIndex] = shelf.copyWith(slots: slots);
    rotationSteps += 1;
    angle += (clockwise ? 1 : -1) * (6.28318530718 / slotCount);
  }

  @override
  void tick(double dt) {
    if (reducedMotion) return;
    if (rotateMode != 'auto' && rotateMode != 'continuous') return;
    _accum += dt * speed;
    if (_accum >= 1.0) {
      _accum = 0;
      rotate();
    }
  }

  @override
  void onMoveCompleted(BoardPos from, BoardPos to) {
    if (rotateMode == 'on_move') rotate();
  }

  @override
  void onShelfCleared(int shelfIndex, String type) {
    if (rotateMode == 'on_clear') rotate();
  }

  @override
  String? get objectiveHint => 'The tray rotates — plan your placements!';

  @override
  Map<String, dynamic> saveState() => {
        'angle': angle,
        'rotationSteps': rotationSteps,
        'clockwise': clockwise,
        'shelfIndex': shelfIndex,
        'accum': _accum,
      };

  @override
  void loadState(Map<String, dynamic> json) {
    angle = (json['angle'] as num?)?.toDouble() ?? 0;
    rotationSteps = json['rotationSteps'] as int? ?? 0;
    clockwise = json['clockwise'] as bool? ?? true;
    shelfIndex = json['shelfIndex'] as int? ?? shelfIndex;
    _accum = (json['accum'] as num?)?.toDouble() ?? 0;
  }
}
