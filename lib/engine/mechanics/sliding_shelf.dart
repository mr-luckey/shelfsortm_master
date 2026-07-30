import '../match_engine.dart';
import 'level_mechanic.dart';
import 'mechanic_ids.dart';

/// Shelf slides horizontally to reveal/hide slots (PRD §6A.6).
class SlidingShelfMechanic extends LevelMechanic {
  MatchEngine? _engine;
  /// Shelf indices that slide.
  List<int> shelfIndices = [];
  String direction = 'horizontal';
  /// Trigger: 'auto' | 'on_move' | 'on_clear'
  String trigger = 'on_move';
  double speed = 0.5;
  double _phase = 0;
  int slideState = 0; // 0 = home, 1 = shifted
  bool reducedMotion = false;

  @override
  String get id => MechanicIds.slidingShelves;

  @override
  void initialize(MatchEngine engine, Map<String, dynamic> config) {
    _engine = engine;
    shelfIndices = (config['shelfIndices'] as List?)
            ?.map((e) => e as int)
            .toList() ??
        [0];
    direction = config['direction'] as String? ?? 'horizontal';
    trigger = config['trigger'] as String? ?? 'on_move';
    speed = (config['speed'] as num?)?.toDouble() ?? 0.5;
    slideState = 0;
    _phase = 0;
    _applyAccess();
  }

  void _applyAccess() {
    final e = _engine;
    if (e == null) return;
    for (final si in shelfIndices) {
      if (si < 0 || si >= e.shelves.length) continue;
      final shelf = e.shelves[si];
      final slots = <dynamic>[];
      for (var i = 0; i < shelf.slots.length; i++) {
        // When shifted, leftmost/rightmost may become inaccessible
        final accessible = slideState == 0
            ? true
            : (direction == 'left'
                ? i > 0
                : i < shelf.slots.length - 1);
        slots.add(shelf.slots[i].copyWith(accessible: accessible));
      }
      e.shelves[si] = shelf.copyWith(
        slots: List.from(slots),
        slideOffset: slideState == 0 ? 0 : (direction == 'left' ? -1 : 1),
      );
    }
  }

  void toggle() {
    slideState = 1 - slideState;
    _applyAccess();
  }

  @override
  void tick(double dt) {
    if (reducedMotion || trigger != 'auto') return;
    _phase += dt * speed;
    if (_phase >= 1.0) {
      _phase = 0;
      toggle();
    }
  }

  @override
  void onMoveCompleted(BoardPos from, BoardPos to) {
    if (trigger == 'on_move') toggle();
  }

  @override
  void onShelfCleared(int shelfIndex, String type) {
    if (trigger == 'on_clear') toggle();
  }

  @override
  bool validateMove(BoardPos from, BoardPos to) {
    final e = _engine;
    if (e == null) return true;
    if (to.shelfIndex < 0 || to.shelfIndex >= e.shelves.length) return false;
    final slot = e.shelves[to.shelfIndex].slots[to.slotIndex];
    return slot.accessible;
  }

  @override
  bool canInteract(BoardPos pos) {
    final e = _engine;
    if (e == null) return true;
    if (pos.shelfIndex < 0 || pos.shelfIndex >= e.shelves.length) return true;
    return e.shelves[pos.shelfIndex].slots[pos.slotIndex].accessible;
  }

  @override
  String? get objectiveHint => 'Watch the sliding shelf — some slots hide!';

  @override
  Map<String, dynamic> saveState() => {
        'slideState': slideState,
        'phase': _phase,
        'shelfIndices': shelfIndices,
      };

  @override
  void loadState(Map<String, dynamic> json) {
    slideState = json['slideState'] as int? ?? 0;
    _phase = (json['phase'] as num?)?.toDouble() ?? 0;
    shelfIndices = (json['shelfIndices'] as List?)
            ?.map((e) => e as int)
            .toList() ??
        shelfIndices;
    _applyAccess();
  }
}
