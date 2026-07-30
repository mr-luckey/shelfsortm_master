import '../match_engine.dart';
import 'level_mechanic.dart';
import 'mechanic_ids.dart';

/// Lock types for items that cannot move until a condition is met (PRD §6A.9).
enum LockType {
  color,
  type,
  key,
  sequence,
  shelf,
}

class ItemLock {
  final int shelfIndex;
  final int slotIndex;
  final LockType type;
  final String? target; // color name, type name, or key item id
  final int? shelfTarget;
  final int sequenceNeeded;
  bool unlocked;

  ItemLock({
    required this.shelfIndex,
    required this.slotIndex,
    required this.type,
    this.target,
    this.shelfTarget,
    this.sequenceNeeded = 3,
    this.unlocked = false,
  });

  Map<String, dynamic> toJson() => {
        'shelfIndex': shelfIndex,
        'slotIndex': slotIndex,
        'type': type.name,
        if (target != null) 'target': target,
        if (shelfTarget != null) 'shelfTarget': shelfTarget,
        'sequenceNeeded': sequenceNeeded,
        'unlocked': unlocked,
      };

  factory ItemLock.fromJson(Map<String, dynamic> json) => ItemLock(
        shelfIndex: json['shelfIndex'] as int,
        slotIndex: json['slotIndex'] as int,
        type: LockType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => LockType.sequence,
        ),
        target: json['target'] as String?,
        shelfTarget: json['shelfTarget'] as int?,
        sequenceNeeded: json['sequenceNeeded'] as int? ?? 3,
        unlocked: json['unlocked'] as bool? ?? false,
      );
}

class LockedItemMechanic extends LevelMechanic {
  MatchEngine? _engine;
  final List<ItemLock> locks = [];
  int correctStreak = 0;

  @override
  String get id => MechanicIds.lockedItems;

  @override
  void initialize(MatchEngine engine, Map<String, dynamic> config) {
    _engine = engine;
    locks.clear();
    correctStreak = 0;
    final raw = config['locks'] as List? ?? [];
    for (final e in raw) {
      final m = e as Map<String, dynamic>;
      // Support "slot": "shelfId:slot" or explicit indices
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
      final cond = m['condition'] as String? ?? 'sequence';
      final type = switch (cond) {
        'color' || 'color_lock' => LockType.color,
        'type' || 'type_lock' => LockType.type,
        'key' || 'key_lock' => LockType.key,
        'shelf' || 'shelf_complete' || 'shelf_lock' => LockType.shelf,
        _ => LockType.sequence,
      };
      locks.add(
        ItemLock(
          shelfIndex: shelfIndex,
          slotIndex: slotIndex,
          type: type,
          target: m['target']?.toString(),
          shelfTarget: m['shelfTarget'] as int? ??
              (m['target'] is int ? m['target'] as int : null),
          sequenceNeeded: m['sequenceNeeded'] as int? ?? 3,
        ),
      );
    }
    _applyLocks();
  }

  void _applyLocks() {
    final e = _engine;
    if (e == null) return;
    for (final lock in locks) {
      if (lock.unlocked) continue;
      if (lock.shelfIndex < 0 || lock.shelfIndex >= e.shelves.length) continue;
      final shelf = e.shelves[lock.shelfIndex];
      if (lock.slotIndex < 0 || lock.slotIndex >= shelf.slots.length) continue;
      final slot = shelf.slots[lock.slotIndex];
      final front = slot.front;
      if (front == null) continue;
      e.shelves[lock.shelfIndex] = shelf.withSlot(
        lock.slotIndex,
        slot.copyWith(
          isLocked: true,
          lockCondition: lock.type.name,
          stack: [
            front.copyWith(isLocked: true),
            ...slot.stack.skip(1),
          ],
        ),
      );
    }
  }

  void _unlock(ItemLock lock) {
    final e = _engine;
    if (e == null || lock.unlocked) return;
    lock.unlocked = true;
    if (lock.shelfIndex < 0 || lock.shelfIndex >= e.shelves.length) return;
    final shelf = e.shelves[lock.shelfIndex];
    if (lock.slotIndex < 0 || lock.slotIndex >= shelf.slots.length) return;
    final slot = shelf.slots[lock.slotIndex];
    final front = slot.front;
    e.shelves[lock.shelfIndex] = shelf.withSlot(
      lock.slotIndex,
      slot.copyWith(
        isLocked: false,
        lockCondition: null,
        stack: front == null
            ? slot.stack
            : [
                front.copyWith(isLocked: false),
                ...slot.stack.skip(1),
              ],
      ),
    );
  }

  @override
  bool canInteract(BoardPos pos) {
    for (final lock in locks) {
      if (!lock.unlocked &&
          lock.shelfIndex == pos.shelfIndex &&
          lock.slotIndex == pos.slotIndex) {
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
    _evaluateLocks();
  }

  @override
  void onShelfCleared(int shelfIndex, String type) {
    for (final lock in locks) {
      if (lock.unlocked) continue;
      if (lock.type == LockType.shelf &&
          (lock.shelfTarget == shelfIndex || lock.shelfTarget == null)) {
        _unlock(lock);
      }
      if (lock.type == LockType.type && lock.target == type) {
        _unlock(lock);
      }
      if (lock.type == LockType.color && lock.target != null) {
        // Color lock: unlock when any clear happens of matching color on board
        // We use type as proxy when tint is mono; unlock on any shelf clear.
        _unlock(lock);
      }
    }
  }

  void _evaluateLocks() {
    for (final lock in locks) {
      if (lock.unlocked) continue;
      if (lock.type == LockType.sequence &&
          correctStreak >= lock.sequenceNeeded) {
        _unlock(lock);
      }
    }
  }

  @override
  String? get objectiveHint => 'Unlock sealed items by meeting their condition.';

  @override
  Map<String, dynamic> saveState() => {
        'locks': locks.map((e) => e.toJson()).toList(),
        'correctStreak': correctStreak,
      };

  @override
  void loadState(Map<String, dynamic> json) {
    locks
      ..clear()
      ..addAll(
        (json['locks'] as List? ?? [])
            .map((e) => ItemLock.fromJson(e as Map<String, dynamic>)),
      );
    correctStreak = json['correctStreak'] as int? ?? 0;
    _applyLocks();
    for (final lock in locks.where((l) => l.unlocked)) {
      _unlock(lock);
    }
  }
}
