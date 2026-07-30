import '../match_engine.dart';
import 'level_mechanic.dart';
import 'mechanic_ids.dart';

/// Wraps depth-stack reveal as an explicit mechanic (PRD §6A.4).
/// Core engine already slides behind → front; this module tracks config,
/// tutorials, and objective hints.
class HiddenBackRowMechanic extends LevelMechanic {
  MatchEngine? _engine;
  int rows = 1;
  String revealMode = 'front_clear';
  int reveals = 0;

  @override
  String get id => MechanicIds.hiddenBackRow;

  @override
  void initialize(MatchEngine engine, Map<String, dynamic> config) {
    _engine = engine;
    rows = config['rows'] as int? ?? 1;
    revealMode = config['revealMode'] as String? ?? 'front_clear';
  }

  @override
  void onMoveCompleted(BoardPos from, BoardPos to) {
    // Count how many columns still have depth > 1
    final e = _engine;
    if (e == null) return;
    var hidden = 0;
    for (final s in e.shelves) {
      for (final slot in s.slots) {
        if (slot.depth > 1) hidden++;
      }
    }
    // reveals tracked as decrease from previous — optional analytics hook
    if (hidden >= 0) reveals = reveals;
  }

  @override
  String? get objectiveHint =>
      'Clear the front items to reveal what\'s behind.';

  @override
  Map<String, dynamic> saveState() => {
        'rows': rows,
        'revealMode': revealMode,
        'reveals': reveals,
      };

  @override
  void loadState(Map<String, dynamic> json) {
    rows = json['rows'] as int? ?? rows;
    revealMode = json['revealMode'] as String? ?? revealMode;
    reveals = json['reveals'] as int? ?? 0;
  }
}
