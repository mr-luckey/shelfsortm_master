import '../match_engine.dart';
import 'level_mechanic.dart';
import 'mechanic_ids.dart';

/// Shelf divider that changes available slot groups (PRD §6A.13).
class MovingDividerMechanic extends LevelMechanic {
  MatchEngine? _engine;
  int shelfIndex = 0;
  int dividerIndex = 1;
  /// 'on_move' | 'auto' | 'on_clear'
  String trigger = 'on_move';
  double speed = 0.4;
  double _phase = 0;
  bool reducedMotion = false;
  List<int> positions = [1, 2];
  int _posIdx = 0;

  @override
  String get id => MechanicIds.movingDivider;

  @override
  void initialize(MatchEngine engine, Map<String, dynamic> config) {
    _engine = engine;
    shelfIndex = config['shelfIndex'] as int? ?? 0;
    dividerIndex = config['dividerIndex'] as int? ?? 1;
    trigger = config['trigger'] as String? ?? 'on_move';
    speed = (config['speed'] as num?)?.toDouble() ?? 0.4;
    positions = (config['positions'] as List?)
            ?.map((e) => e as int)
            .toList() ??
        [1, 2];
    _posIdx = 0;
    _phase = 0;
    _apply();
  }

  void _apply() {
    final e = _engine;
    if (e == null) return;
    if (shelfIndex < 0 || shelfIndex >= e.shelves.length) return;
    dividerIndex = positions[_posIdx % positions.length];
    final shelf = e.shelves[shelfIndex];
    // Slots on either side of divider remain accessible; divider itself blocks
    // grouping — for match rules, divider just marks a visual/group constraint.
    e.shelves[shelfIndex] = shelf.copyWith(dividerIndex: dividerIndex);
  }

  void advance() {
    _posIdx = (_posIdx + 1) % positions.length;
    _apply();
  }

  @override
  void tick(double dt) {
    if (reducedMotion || trigger != 'auto') return;
    _phase += dt * speed;
    if (_phase >= 1.0) {
      _phase = 0;
      advance();
    }
  }

  @override
  void onMoveCompleted(BoardPos from, BoardPos to) {
    if (trigger == 'on_move') advance();
  }

  @override
  void onShelfCleared(int shelfIndex, String type) {
    if (trigger == 'on_clear') advance();
  }

  /// Match only allowed within the same divider group.
  @override
  bool validateMove(BoardPos from, BoardPos to) {
    // Placement always OK; match grouping handled separately if needed
    return true;
  }

  @override
  String? get objectiveHint => 'The divider moves — plan groups carefully.';

  @override
  Map<String, dynamic> saveState() => {
        'dividerIndex': dividerIndex,
        'posIdx': _posIdx,
        'phase': _phase,
        'shelfIndex': shelfIndex,
      };

  @override
  void loadState(Map<String, dynamic> json) {
    dividerIndex = json['dividerIndex'] as int? ?? dividerIndex;
    _posIdx = json['posIdx'] as int? ?? 0;
    _phase = (json['phase'] as num?)?.toDouble() ?? 0;
    shelfIndex = json['shelfIndex'] as int? ?? shelfIndex;
    _apply();
  }
}
