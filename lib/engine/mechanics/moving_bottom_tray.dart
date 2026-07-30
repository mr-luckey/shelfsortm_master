import '../match_engine.dart';
import '../../models/item.dart';
import '../../models/shelf.dart';
import 'level_mechanic.dart';
import 'mechanic_ids.dart';

/// Holding tray at the bottom that ping-pongs horizontally (PRD §6A.5).
class MovingBottomTrayMechanic extends LevelMechanic {
  MatchEngine? _engine;
  int slotCount = 4;
  String movementMode = 'ping_pong';
  double speed = 0.65;
  double pauseAtEnds = 0.4;

  /// Normalized position 0..1 along the travel path.
  double position = 0;
  int direction = 1;
  double _pauseLeft = 0;
  bool reducedMotion = false;

  /// Items currently on the tray.
  List<GameItem?> traySlots = [];

  @override
  String get id => MechanicIds.movingBottomTray;

  @override
  void initialize(MatchEngine engine, Map<String, dynamic> config) {
    _engine = engine;
    slotCount = config['slotCount'] as int? ?? 4;
    movementMode = config['movementMode'] as String? ?? 'ping_pong';
    speed = (config['speed'] as num?)?.toDouble() ?? 0.65;
    pauseAtEnds = (config['pauseAtEnds'] as num?)?.toDouble() ?? 0.4;
    traySlots = List<GameItem?>.filled(slotCount, null);
    position = 0;
    direction = 1;
    _pauseLeft = 0;
  }

  @override
  void tick(double dt) {
    if (reducedMotion) return;
    if (_pauseLeft > 0) {
      _pauseLeft -= dt;
      return;
    }
    position += direction * speed * dt;
    if (position >= 1) {
      position = 1;
      direction = -1;
      _pauseLeft = pauseAtEnds;
    } else if (position <= 0) {
      position = 0;
      direction = 1;
      _pauseLeft = pauseAtEnds;
    }
  }

  int get emptyTrayIndex => traySlots.indexWhere((e) => e == null);

  bool get hasEmpty => emptyTrayIndex >= 0;

  /// Place selected item onto an empty tray slot.
  bool placeOntoTray(GameItem item) {
    final i = emptyTrayIndex;
    if (i < 0) return false;
    traySlots[i] = item;
    return true;
  }

  /// Take item from tray slot back to an empty board column.
  GameItem? takeFromTray(int index) {
    if (index < 0 || index >= traySlots.length) return null;
    final item = traySlots[index];
    traySlots[index] = null;
    return item;
  }

  /// Sync tray into engine as a temporary dock shelf (shelfIndex = -1 style).
  void syncToEngine() {
    final e = _engine;
    if (e == null) return;
    // Represent tray as last temporary dock shelf if present
    final dockIdx = e.shelves.indexWhere((s) => s.isDock);
    if (dockIdx < 0) {
      final id =
          e.shelves.map((s) => s.shelfId).fold(0, (a, b) => a > b ? a : b) + 1;
      final slots = List.generate(
        slotCount,
        (i) => traySlots[i] == null
            ? const ShelfSlot()
            : ShelfSlot.front(traySlots[i]!),
      );
      e.shelves = [
        ...e.shelves,
        Shelf(
          shelfId: id,
          slotCount: slotCount,
          slots: slots,
          isDock: true,
          isTemporary: true,
        ),
      ];
    } else {
      final slots = List.generate(
        slotCount,
        (i) => traySlots[i] == null
            ? const ShelfSlot()
            : ShelfSlot.front(traySlots[i]!),
      );
      e.shelves[dockIdx] = e.shelves[dockIdx].copyWith(slots: slots);
    }
  }

  @override
  void start() => syncToEngine();

  @override
  String? get objectiveHint =>
      'The tray is moving! Tap a slot when it\'s ready.';

  @override
  Map<String, dynamic> saveState() => {
        'position': position,
        'direction': direction,
        'pauseLeft': _pauseLeft,
        'traySlots': traySlots.map((e) => e?.toJson()).toList(),
        'slotCount': slotCount,
        'speed': speed,
      };

  @override
  void loadState(Map<String, dynamic> json) {
    position = (json['position'] as num?)?.toDouble() ?? 0;
    direction = json['direction'] as int? ?? 1;
    _pauseLeft = (json['pauseLeft'] as num?)?.toDouble() ?? 0;
    slotCount = json['slotCount'] as int? ?? slotCount;
    speed = (json['speed'] as num?)?.toDouble() ?? speed;
    final list = json['traySlots'] as List? ?? [];
    traySlots = List.generate(slotCount, (i) {
      if (i >= list.length || list[i] == null) return null;
      return GameItem.fromJson(list[i] as Map<String, dynamic>);
    });
    syncToEngine();
  }
}
