import '../match_engine.dart';
import '../../models/item.dart';
import 'level_mechanic.dart';
import 'mechanic_ids.dart';

/// Items travel along a conveyor belt (PRD §6A.8).
class ConveyorShelfMechanic extends LevelMechanic {
  // ignore: unused_field
  MatchEngine? _engine;
  double speed = 0.35;
  int laneCount = 1;
  int visibleSlots = 4;
  bool paused = false;
  bool canPause = false;
  bool reducedMotion = false;

  /// Queue of items waiting to enter the belt.
  final List<GameItem> queue = [];
  /// Currently visible belt slots (null = empty).
  List<GameItem?> belt = [];
  double _phase = 0;

  @override
  String get id => MechanicIds.conveyorShelf;

  @override
  void initialize(MatchEngine engine, Map<String, dynamic> config) {
    _engine = engine;
    speed = (config['speed'] as num?)?.toDouble() ?? 0.35;
    laneCount = config['laneCount'] as int? ?? 1;
    visibleSlots = config['visibleSlots'] as int? ?? 4;
    canPause = config['canPause'] as bool? ?? false;
    paused = false;
    _phase = 0;
    belt = List<GameItem?>.filled(visibleSlots, null);
    queue.clear();

    // Pull items from config queue or from engine.level.queue
    final ids = (config['queue'] as List?)?.map((e) => e as String).toList() ??
        engine.level.queue;
    for (final id in ids) {
      queue.add(GameItem.fromId(id));
    }
  }

  @override
  void tick(double dt) {
    if (paused || reducedMotion) return;
    _phase += dt * speed;
    if (_phase >= 1.0) {
      _phase = 0;
      _advance();
    }
  }

  void _advance() {
    // Rightmost exits (lost if not picked — fair: only exit empty or push to reserve)
    // Items shift right; left gets next from queue
    for (var i = belt.length - 1; i > 0; i--) {
      if (belt[i] == null && belt[i - 1] != null) {
        belt[i] = belt[i - 1];
        belt[i - 1] = null;
      }
    }
    // Exit rightmost if full cycle — wrap into queue end (never lose items)
    if (belt.last != null && belt.every((e) => e != null)) {
      // Can't advance until player picks something
      return;
    }
    if (belt.first == null && queue.isNotEmpty) {
      belt[0] = queue.removeAt(0);
    } else if (belt.last != null) {
      // Cycle: move last to queue back if left is empty path exists
      final exiting = belt.last;
      // Shift all right
      for (var i = belt.length - 1; i > 0; i--) {
        belt[i] = belt[i - 1];
      }
      belt[0] = null;
      if (exiting != null) queue.add(exiting);
      if (queue.isNotEmpty && belt[0] == null) {
        belt[0] = queue.removeAt(0);
      }
    }
  }

  GameItem? pickFromBelt(int index) {
    if (index < 0 || index >= belt.length) return null;
    final item = belt[index];
    belt[index] = null;
    return item;
  }

  void togglePause() {
    if (canPause) paused = !paused;
  }

  @override
  String? get objectiveHint =>
      'Pick items from the conveyor before they cycle away.';

  @override
  Map<String, dynamic> saveState() => {
        'phase': _phase,
        'paused': paused,
        'belt': belt.map((e) => e?.toJson()).toList(),
        'queue': queue.map((e) => e.toJson()).toList(),
      };

  @override
  void loadState(Map<String, dynamic> json) {
    _phase = (json['phase'] as num?)?.toDouble() ?? 0;
    paused = json['paused'] as bool? ?? false;
    final b = json['belt'] as List? ?? [];
    belt = List.generate(visibleSlots, (i) {
      if (i >= b.length || b[i] == null) return null;
      return GameItem.fromJson(b[i] as Map<String, dynamic>);
    });
    queue
      ..clear()
      ..addAll(
        (json['queue'] as List? ?? [])
            .map((e) => GameItem.fromJson(e as Map<String, dynamic>)),
      );
  }
}
