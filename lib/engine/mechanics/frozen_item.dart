import '../match_engine.dart';
import 'level_mechanic.dart';
import 'mechanic_ids.dart';

class FrozenSlot {
  final int shelfIndex;
  final int slotIndex;
  int layers;
  final String unlock; // shelf_complete | warm_place | sequence

  FrozenSlot({
    required this.shelfIndex,
    required this.slotIndex,
    this.layers = 1,
    this.unlock = 'sequence',
  });

  bool get isFrozen => layers > 0;

  Map<String, dynamic> toJson() => {
        'shelfIndex': shelfIndex,
        'slotIndex': slotIndex,
        'layers': layers,
        'unlock': unlock,
      };

  factory FrozenSlot.fromJson(Map<String, dynamic> json) => FrozenSlot(
        shelfIndex: json['shelfIndex'] as int,
        slotIndex: json['slotIndex'] as int,
        layers: json['layers'] as int? ?? 1,
        unlock: json['unlock'] as String? ?? 'sequence',
      );
}

/// Temporarily frozen items that crack then break (PRD §6A.12).
class FrozenItemMechanic extends LevelMechanic {
  MatchEngine? _engine;
  final List<FrozenSlot> frozen = [];
  int correctStreak = 0;

  @override
  String get id => MechanicIds.frozenItems;

  @override
  void initialize(MatchEngine engine, Map<String, dynamic> config) {
    _engine = engine;
    frozen.clear();
    correctStreak = 0;
    final raw = config['frozen'] as List? ?? [];
    for (final e in raw) {
      final m = e as Map<String, dynamic>;
      int shelfIndex = m['shelfIndex'] as int? ?? 0;
      int slotIndex = m['slotIndex'] as int? ?? 0;
      if (m['slot'] is String) {
        final parts = (m['slot'] as String).split(':');
        if (parts.length == 2) {
          final shelfId = int.tryParse(parts[0]) ?? 1;
          slotIndex = int.tryParse(parts[1]) ?? 0;
          shelfIndex =
              engine.shelves.indexWhere((s) => s.shelfId == shelfId);
          if (shelfIndex < 0) shelfIndex = 0;
        }
      }
      final f = FrozenSlot(
        shelfIndex: shelfIndex,
        slotIndex: slotIndex,
        layers: m['layers'] as int? ?? 1,
        unlock: m['unlock'] as String? ?? 'sequence',
      );
      frozen.add(f);
      _apply(f);
    }
  }

  void _apply(FrozenSlot f) {
    final e = _engine;
    if (e == null || !f.isFrozen) return;
    if (f.shelfIndex < 0 || f.shelfIndex >= e.shelves.length) return;
    final shelf = e.shelves[f.shelfIndex];
    if (f.slotIndex < 0 || f.slotIndex >= shelf.slots.length) return;
    final slot = shelf.slots[f.slotIndex];
    final front = slot.front;
    if (front == null) return;
    e.shelves[f.shelfIndex] = shelf.withSlot(
      f.slotIndex,
      slot.copyWith(
        freezeLayers: f.layers,
        stack: [
          front.copyWith(iceLayers: f.layers),
          ...slot.stack.skip(1),
        ],
      ),
    );
  }

  void _crack(FrozenSlot f) {
    if (!f.isFrozen) return;
    f.layers -= 1;
    final e = _engine;
    if (e == null) return;
    if (f.shelfIndex < 0 || f.shelfIndex >= e.shelves.length) return;
    final shelf = e.shelves[f.shelfIndex];
    if (f.slotIndex < 0 || f.slotIndex >= shelf.slots.length) return;
    final slot = shelf.slots[f.slotIndex];
    final front = slot.front;
    e.shelves[f.shelfIndex] = shelf.withSlot(
      f.slotIndex,
      slot.copyWith(
        freezeLayers: f.layers,
        stack: front == null
            ? slot.stack
            : [
                front.copyWith(iceLayers: f.layers),
                ...slot.stack.skip(1),
              ],
      ),
    );
  }

  @override
  bool canInteract(BoardPos pos) {
    for (final f in frozen) {
      if (f.isFrozen &&
          f.shelfIndex == pos.shelfIndex &&
          f.slotIndex == pos.slotIndex) {
        return false;
      }
    }
    return true;
  }

  @override
  bool validateMove(BoardPos from, BoardPos to) => canInteract(from);

  @override
  void onMoveCompleted(BoardPos from, BoardPos to) {
    correctStreak += 1;
    for (final f in frozen) {
      if (!f.isFrozen) continue;
      if (f.unlock == 'sequence' && correctStreak >= 3) {
        _crack(f);
        correctStreak = 0;
      }
      if (f.unlock == 'warm_place') {
        final e = _engine;
        if (e == null) continue;
        final item = e.itemAt(to);
        final warm = {'red', 'orange', 'yellow', 'pink'};
        if (item != null && warm.contains(item.color)) {
          _crack(f);
        }
      }
    }
  }

  @override
  void onShelfCleared(int shelfIndex, String type) {
    for (final f in frozen) {
      if (!f.isFrozen) continue;
      if (f.unlock == 'shelf_complete') _crack(f);
    }
  }

  @override
  String? get objectiveHint => 'Crack the ice to free frozen items.';

  @override
  Map<String, dynamic> saveState() => {
        'frozen': frozen.map((e) => e.toJson()).toList(),
        'correctStreak': correctStreak,
      };

  @override
  void loadState(Map<String, dynamic> json) {
    frozen
      ..clear()
      ..addAll(
        (json['frozen'] as List? ?? [])
            .map((e) => FrozenSlot.fromJson(e as Map<String, dynamic>)),
      );
    correctStreak = json['correctStreak'] as int? ?? 0;
    for (final f in frozen) {
      _apply(f);
    }
  }
}
