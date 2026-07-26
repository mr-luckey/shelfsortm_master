import 'package:equatable/equatable.dart';

import '../models/item.dart';
import '../models/level_data.dart';
import '../models/shelf.dart';

enum GameStatus { ready, playing, paused, won, lostTime, lostSpace }

class BoardPos extends Equatable {
  final int shelfIndex;
  final int slotIndex;

  const BoardPos(this.shelfIndex, this.slotIndex);

  @override
  List<Object?> get props => [shelfIndex, slotIndex];
}

class MatchClear extends Equatable {
  final int shelfIndex;
  final String type;

  const MatchClear({required this.shelfIndex, required this.type});

  @override
  List<Object?> get props => [shelfIndex, type];
}

/// Goods Puzzle: Sort Challenge (Falcon) exact core:
/// - Shelves filled with mixed goods + empty buffer shelves
/// - Each shelf has [slotsPerShelf] capacity (default 3)
/// - Tap/drag a good → empty slot on any shelf
/// - When a shelf has 3 identical goods → auto clear
/// - Empty buffers are working space (critical)
/// - Timer; win when board empty
class MatchEngine {
  final LevelData level;
  List<Shelf> shelves;
  int moves;
  int matches;
  int combo;
  int timeLeft;
  bool frozen;
  GameStatus status;
  MatchClear? lastClear;
  BoardPos? selected;
  final List<_Snap> _undo = [];

  MatchEngine({required this.level})
      : shelves = [],
        moves = 0,
        matches = 0,
        combo = 0,
        timeLeft = level.timeLimit,
        frozen = false,
        status = GameStatus.playing {
    shelves = level.buildSortedChallengeBoard();
    // Clear accidental opening matches
    for (var i = 0; i < shelves.length; i++) {
      _resolveMatches(i);
    }
  }

  int get emptySlotCount => shelves.fold<int>(
        0,
        (n, s) => n + s.slots.where((x) => x.isEmpty).length,
      );

  int get itemCount => shelves.fold<int>(0, (n, s) => n + s.occupiedCount);

  int get stars =>
      level.starThresholds.starsForTimeLeft(timeLeft, level.timeLimit);

  bool get isWon => status == GameStatus.won;
  bool get isLost =>
      status == GameStatus.lostTime || status == GameStatus.lostSpace;

  /// Legacy belt compat for UI that still reads belt — empty.
  List<GameItem?> get belt => const [];
  int get reserveCount => 0;

  GameItem? itemAt(BoardPos pos) {
    if (pos.shelfIndex < 0 || pos.shelfIndex >= shelves.length) return null;
    final slots = shelves[pos.shelfIndex].slots;
    if (pos.slotIndex < 0 || pos.slotIndex >= slots.length) return null;
    return slots[pos.slotIndex].item;
  }

  void tickSecond() {
    if (status != GameStatus.playing || frozen) return;
    if (timeLeft <= 0) return;
    timeLeft -= 1;
    if (timeLeft <= 0) {
      timeLeft = 0;
      status = GameStatus.lostTime;
    }
  }

  void setFrozen(bool v) => frozen = v;

  void setPaused(bool v) {
    if (status == GameStatus.won || isLost) return;
    status = v ? GameStatus.paused : GameStatus.playing;
  }

  /// Tap select / tap empty to move (Sort Challenge primary control).
  bool tap(BoardPos pos) {
    if (status != GameStatus.playing) return false;
    lastClear = null;

    if (selected == null) {
      final item = itemAt(pos);
      if (item == null) return false;
      selected = pos;
      return true;
    }

    if (selected == pos) {
      selected = null;
      return true;
    }

    // Reselect another item
    if (itemAt(pos) != null) {
      selected = pos;
      return true;
    }

    final ok = move(selected!, pos);
    if (ok) selected = null;
    return ok;
  }

  /// Move good from → empty to. Any shelf empty slot allowed.
  bool move(BoardPos from, BoardPos to) {
    if (status != GameStatus.playing) return false;
    if (from == to) return false;

    final item = itemAt(from);
    if (item == null) return false;
    if (itemAt(to) != null) return false;

    lastClear = null;
    _pushUndo();

    shelves[from.shelfIndex] =
        shelves[from.shelfIndex].withSlot(from.slotIndex, const ShelfSlot());
    shelves[to.shelfIndex] =
        shelves[to.shelfIndex].withSlot(to.slotIndex, ShelfSlot(item: item));
    moves += 1;

    _resolveMatches(to.shelfIndex);
    _checkEnd();
    return true;
  }

  void _resolveMatches(int shelfIndex) {
    while (true) {
      final current = shelves[shelfIndex];
      final matchType = current.matchableType();
      if (matchType == null) break;

      final indexes = <int>[];
      final slots = List<ShelfSlot>.from(current.slots);
      for (var i = 0; i < slots.length && indexes.length < 3; i++) {
        if (slots[i].item?.type == matchType) {
          indexes.add(i);
          slots[i] = const ShelfSlot();
        }
      }
      shelves[shelfIndex] = current.copyWith(slots: slots);
      matches += 1;
      combo += 1;
      lastClear = MatchClear(shelfIndex: shelfIndex, type: matchType);
    }
  }

  void _checkEnd() {
    if (itemCount == 0) {
      status = GameStatus.won;
      return;
    }
    // Soft stuck: no empty slots (shouldn't happen with buffers normally)
    if (emptySlotCount == 0) {
      status = GameStatus.lostSpace;
    } else if (status == GameStatus.lostSpace && emptySlotCount > 0) {
      status = GameStatus.playing;
    }
  }

  bool undo() {
    if (_undo.isEmpty) return false;
    if (isLost) status = GameStatus.playing;
    final s = _undo.removeLast();
    shelves = s.shelves;
    moves = s.moves;
    matches = s.matches;
    combo = s.combo;
    timeLeft = s.timeLeft;
    lastClear = null;
    selected = null;
    return true;
  }

  void shuffleBoard() {
    if (status != GameStatus.playing) return;
    _pushUndo();
    final items = <GameItem>[];
    for (final shelf in shelves) {
      for (final slot in shelf.slots) {
        if (slot.item != null) items.add(slot.item!);
      }
    }
    items.shuffle();
    // Rebuild: keep same shelf structure, refill randomly leaving same empties
    final empties = emptySlotCount;
    final positions = <BoardPos>[];
    for (var si = 0; si < shelves.length; si++) {
      shelves[si] = shelves[si].copyWith(
        slots: List.generate(shelves[si].slotCount, (_) => const ShelfSlot()),
      );
      for (var slot = 0; slot < shelves[si].slotCount; slot++) {
        positions.add(BoardPos(si, slot));
      }
    }
    positions.shuffle();
    for (var i = 0; i < items.length; i++) {
      final p = positions[i];
      shelves[p.shelfIndex] = shelves[p.shelfIndex]
          .withSlot(p.slotIndex, ShelfSlot(item: items[i]));
    }
    // resolve accidental matches
    for (var i = 0; i < shelves.length; i++) {
      _resolveMatches(i);
    }
    _checkEnd();
    // silence unused
    assert(empties >= 0);
  }

  // aliases used by boosters
  void shuffleBelt() => shuffleBoard();

  int magnetClear(String type) {
    if (status != GameStatus.playing) return 0;
    _pushUndo();
    var removed = 0;
    for (var si = 0; si < shelves.length && removed < 3; si++) {
      final slots = List<ShelfSlot>.from(shelves[si].slots);
      for (var i = 0; i < slots.length && removed < 3; i++) {
        if (slots[i].item?.type == type) {
          slots[i] = const ShelfSlot();
          removed++;
        }
      }
      shelves[si] = shelves[si].copyWith(slots: slots);
    }
    if (removed > 0) {
      matches++;
      _checkEnd();
    }
    return removed;
  }

  String? dominantType() {
    final map = <String, int>{};
    for (final s in shelves) {
      for (final slot in s.slots) {
        final t = slot.item?.type;
        if (t != null) map[t] = (map[t] ?? 0) + 1;
      }
    }
    if (map.isEmpty) return null;
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.first.key;
  }

  void addExtraShelf() {
    if (status != GameStatus.playing) return;
    if (shelves.any((s) => s.isTemporary)) return;
    _pushUndo();
    final id =
        shelves.map((s) => s.shelfId).fold(0, (a, b) => a > b ? a : b) + 1;
    final slots = level.slotsPerShelf.clamp(3, 5);
    shelves = [
      ...shelves,
      Shelf(
        shelfId: id,
        slotCount: slots,
        slots: List.generate(slots, (_) => const ShelfSlot()),
        isTemporary: true,
      ),
    ];
    if (status == GameStatus.lostSpace) status = GameStatus.playing;
  }

  void _pushUndo() {
    _undo.add(
      _Snap(
        shelves: shelves
            .map((s) => s.copyWith(slots: List<ShelfSlot>.from(s.slots)))
            .toList(),
        moves: moves,
        matches: matches,
        combo: combo,
        timeLeft: timeLeft,
      ),
    );
    if (_undo.length > 60) _undo.removeAt(0);
  }

  Map<String, dynamic> toSaveJson() => {
        'levelId': level.levelId,
        'shelves': shelves.map((s) => s.toJson()).toList(),
        'moves': moves,
        'matches': matches,
        'combo': combo,
        'timeLeft': timeLeft,
        'frozen': frozen,
        'status': status.name,
      };

  void loadSaveJson(Map<String, dynamic> json) {
    shelves = (json['shelves'] as List)
        .map((e) => Shelf.fromJson(e as Map<String, dynamic>))
        .toList();
    moves = json['moves'] as int? ?? 0;
    matches = json['matches'] as int? ?? 0;
    combo = json['combo'] as int? ?? 0;
    timeLeft = json['timeLeft'] as int? ?? level.timeLimit;
    frozen = json['frozen'] as bool? ?? false;
    status = GameStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => GameStatus.playing,
    );
  }
}

class _Snap {
  final List<Shelf> shelves;
  final int moves;
  final int matches;
  final int combo;
  final int timeLeft;

  _Snap({
    required this.shelves,
    required this.moves,
    required this.matches,
    required this.combo,
    required this.timeLeft,
  });
}
