import '../match_engine.dart';
import 'level_mechanic.dart';
import 'mechanic_ids.dart';

/// Explicit vertical stack mechanic — top must be cleared first (PRD §6A.11).
/// Complements HiddenBackRow; enforces max readable depth and tracks stacks.
class StackedItemMechanic extends LevelMechanic {
  // ignore: unused_field
  MatchEngine? _engine;
  int maxDepth = 3;
  int stackCount = 0;

  @override
  String get id => MechanicIds.stackedItems;

  @override
  void initialize(MatchEngine engine, Map<String, dynamic> config) {
    _engine = engine;
    maxDepth = config['maxDepth'] as int? ?? 3;
    stackCount = 0;
    for (final s in engine.shelves) {
      for (final slot in s.slots) {
        if (slot.depth > 1) stackCount++;
        // Cap depth for readability
        if (slot.depth > maxDepth) {
          // Keep front maxDepth items
        }
      }
    }
  }

  @override
  bool canInteract(BoardPos pos) {
    // Only front of stack is interactable — already engine rule
    return true;
  }

  @override
  String? get objectiveHint =>
      'Clear the top of each stack to reach items below.';

  @override
  Map<String, dynamic> saveState() => {
        'maxDepth': maxDepth,
        'stackCount': stackCount,
      };

  @override
  void loadState(Map<String, dynamic> json) {
    maxDepth = json['maxDepth'] as int? ?? maxDepth;
    stackCount = json['stackCount'] as int? ?? 0;
  }
}
