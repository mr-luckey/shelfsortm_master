import 'package:equatable/equatable.dart';

import '../models/item.dart';
import '../models/level_data.dart';
import '../models/shelf.dart';
import 'mechanics/conveyor_shelf.dart';
import 'mechanics/mechanic_manager.dart';
import 'shelf_wave_manager.dart';

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

/// Goods Puzzle: Sort Challenge — core rules + dynamic mechanics (PRD §6A).
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
  late final MechanicManager mechanics;
  late final ShelfWaveManager waves;
  int maxCombo = 0;
  bool inputLocked = false;
  int? _closingShelfIndex;

  MatchEngine({required this.level})
      : shelves = [],
        moves = 0,
        matches = 0,
        combo = 0,
        timeLeft = level.timeLimit,
        frozen = false,
        status = GameStatus.playing {
    shelves = level.buildSortedChallengeBoard();
    waves = ShelfWaveManager()..initialize(level, shelves);
    mechanics = MechanicManager();
    mechanics.initialize(this);
    _checkEnd();
  }

  int get emptyFrontCount =>
      shelves.fold<int>(0, (n, s) => n + s.emptyFrontCount);

  int get itemCount => shelves.fold<int>(0, (n, s) => n + s.occupiedCount);

  int get setsLeft => waves.wavesRemaining + (itemCount / 3).ceil();

  int get stars {
    if (level.optimalMoves > 0) {
      return level.starsForMoves(moves);
    }
    return level.starThresholds.starsForTimeLeft(timeLeft, level.timeLimit);
  }

  bool get isWon => status == GameStatus.won;
  bool get isLost =>
      status == GameStatus.lostTime || status == GameStatus.lostSpace;

  List<GameItem?> get belt =>
      mechanics.ofType<ConveyorShelfMechanic>()?.belt ?? const [];

  int get reserveCount => 0;

  /// Front item only.
  GameItem? itemAt(BoardPos pos) {
    if (pos.shelfIndex < 0 || pos.shelfIndex >= shelves.length) return null;
    final slots = shelves[pos.shelfIndex].slots;
    if (pos.slotIndex < 0 || pos.slotIndex >= slots.length) return null;
    return slots[pos.slotIndex].front;
  }

  GameItem? peekBehind(BoardPos pos) {
    if (pos.shelfIndex < 0 || pos.shelfIndex >= shelves.length) return null;
    final slots = shelves[pos.shelfIndex].slots;
    if (pos.slotIndex < 0 || pos.slotIndex >= slots.length) return null;
    return slots[pos.slotIndex].peekBehind;
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

  /// Sub-second tick for animated mechanics.
  void tickMechanics(double dt) {
    if (status != GameStatus.playing) return;
    mechanics.tick(dt);
  }

  void setFrozen(bool v) => frozen = v;

  void setPaused(bool v) {
    if (status == GameStatus.won || isLost) return;
    status = v ? GameStatus.paused : GameStatus.playing;
    if (v) {
      mechanics.pause();
    } else {
      mechanics.resume();
    }
  }

  /// Tap front to select → empty column to move. Re-tap same = deselect.
  bool tap(BoardPos pos) {
    if (status != GameStatus.playing || inputLocked) return false;
    lastClear = null;

    if (selected == null) {
      final item = itemAt(pos);
      if (item == null) return false;
      if (!mechanics.canInteract(pos)) return false;
      if (shelves[pos.shelfIndex].slots[pos.slotIndex].frontBlocked) {
        return false;
      }
      selected = pos;
      return true;
    }

    if (selected == pos) {
      selected = null;
      return true;
    }

    if (itemAt(pos) != null) {
      if (!mechanics.canInteract(pos)) return false;
      if (shelves[pos.shelfIndex].slots[pos.slotIndex].frontBlocked) {
        return false;
      }
      selected = pos;
      return true;
    }

    final ok = move(selected!, pos);
    if (ok) selected = null;
    return ok;
  }

  /// Move front from → empty column to.
  bool move(BoardPos from, BoardPos to) {
    if (status != GameStatus.playing || inputLocked) return false;
    if (from == to) return false;

    final item = itemAt(from);
    if (item == null) return false;
    if (!mechanics.canInteract(from)) return false;
    if (shelves[from.shelfIndex].slots[from.slotIndex].frontBlocked) {
      return false;
    }
    if (!mechanics.validateMove(from, to)) return false;

    final toSlot = shelves[to.shelfIndex].slots[to.slotIndex];
    if (!toSlot.isEmpty) return false;
    if (!toSlot.accessible) return false;

    lastClear = null;
    _pushUndo();

    shelves[from.shelfIndex] = shelves[from.shelfIndex].withSlot(
      from.slotIndex,
      shelves[from.shelfIndex].slots[from.slotIndex].withFrontRemoved(),
    );
    shelves[to.shelfIndex] = shelves[to.shelfIndex].withSlot(
      to.slotIndex,
      ShelfSlot.front(item),
    );
    moves += 1;
    final before = matches;

    _resolveMatches(to.shelfIndex);
    if (from.shelfIndex != to.shelfIndex) {
      _resolveMatches(from.shelfIndex);
    }
    if (matches == before) {
      combo = 0;
    } else if (combo > maxCombo) {
      maxCombo = combo;
    }

    mechanics.onMoveCompleted(from, to);
    _checkEnd();
    return true;
  }

  bool swap(BoardPos a, BoardPos b) => false;

  void _resolveMatches(int shelfIndex) {
    final current = shelves[shelfIndex];
    final matchType = current.matchableType();
    if (matchType == null) return;

    matches += 1;
    combo += 1;
    if (combo > maxCombo) maxCombo = combo;
    lastClear = MatchClear(shelfIndex: shelfIndex, type: matchType);
    mechanics.onShelfCleared(shelfIndex, matchType);
    waves.queueNextWave(shelfIndex, current);
    _closingShelfIndex = shelfIndex;
    inputLocked = true;
  }

  /// After door-close animation — empties bay, then opens next wave if any.
  void finishShelfClose(int shelfIndex) {
    if (_closingShelfIndex != shelfIndex) return;
    _closingShelfIndex = null;
    shelves[shelfIndex] = shelves[shelfIndex].copyWith(
      slots: List.generate(
        shelves[shelfIndex].slots.length,
        (_) => const ShelfSlot(),
      ),
    );
    if (!waves.hasPendingWave(shelfIndex)) {
      inputLocked = false;
      _checkEnd();
    }
  }

  /// Called after close animation — loads the next wave into the bay.
  bool openNextWave(int shelfIndex) {
    final wave = waves.takePendingWave(shelfIndex);
    if (wave == null) {
      inputLocked = false;
      _checkEnd();
      return false;
    }
    shelves[shelfIndex] = waves.applyWave(shelves[shelfIndex], wave);
    inputLocked = false;
    _checkEnd();
    return true;
  }

  void unlockInput() {
    inputLocked = false;
    _checkEnd();
  }

  void _checkEnd() {
    if (itemCount == 0 && waves.wavesRemaining == 0) {
      status = GameStatus.won;
      return;
    }
    // Only count shelves that still have items or pending waves
    var playableEmpty = 0;
    for (var i = 0; i < shelves.length; i++) {
      if (waves.finishedShelfIndices.contains(i)) continue;
      playableEmpty += shelves[i].emptyFrontCount;
    }
    if (playableEmpty == 0 && itemCount > 0) {
      status = GameStatus.lostSpace;
    } else if (status == GameStatus.lostSpace && playableEmpty > 0) {
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
    if (s.mechanicState != null) {
      mechanics.loadState(s.mechanicState!);
    }
    _checkEnd();
    return true;
  }

  void shuffleBoard() {
    if (status != GameStatus.playing) return;
    _pushUndo();
    final depths = <BoardPos, int>{};
    final items = <GameItem>[];
    for (var si = 0; si < shelves.length; si++) {
      for (var slot = 0; slot < shelves[si].slots.length; slot++) {
        final stack = shelves[si].slots[slot].stack;
        // Skip locked/frozen/mystery fronts — keep them in place
        if (shelves[si].slots[slot].frontBlocked) continue;
        depths[BoardPos(si, slot)] = stack.length;
        items.addAll(stack);
      }
    }
    items.shuffle();
    var idx = 0;
    for (var si = 0; si < shelves.length; si++) {
      final newSlots = <ShelfSlot>[];
      for (var slot = 0; slot < shelves[si].slots.length; slot++) {
        final existing = shelves[si].slots[slot];
        if (existing.frontBlocked) {
          newSlots.add(existing);
          continue;
        }
        final d = depths[BoardPos(si, slot)] ?? 0;
        final stack = <GameItem>[];
        for (var k = 0; k < d && idx < items.length; k++) {
          stack.add(items[idx++]);
        }
        newSlots.add(existing.copyWith(stack: stack));
      }
      shelves[si] = shelves[si].copyWith(slots: newSlots);
    }
    for (var i = 0; i < shelves.length; i++) {
      _resolveMatches(i);
    }
    _checkEnd();
  }

  void shuffleBelt() => shuffleBoard();

  int hammerRemove(BoardPos pos) {
    if (status != GameStatus.playing) return 0;
    final item = itemAt(pos);
    if (item == null) return 0;
    if (!mechanics.canInteract(pos)) return 0;
    _pushUndo();
    shelves[pos.shelfIndex] = shelves[pos.shelfIndex].withSlot(
      pos.slotIndex,
      shelves[pos.shelfIndex].slots[pos.slotIndex].withFrontRemoved(),
    );
    selected = null;
    _resolveMatches(pos.shelfIndex);
    _checkEnd();
    return 1;
  }

  int magnetClear(String type) {
    if (status != GameStatus.playing) return 0;
    _pushUndo();
    var removed = 0;
    for (var si = 0; si < shelves.length && removed < 3; si++) {
      final slots = List<ShelfSlot>.from(shelves[si].slots);
      for (var i = 0; i < slots.length && removed < 3; i++) {
        if (slots[i].front?.type == type && !slots[i].frontBlocked) {
          slots[i] = slots[i].withFrontRemoved();
          removed++;
        }
      }
      shelves[si] = shelves[si].copyWith(slots: slots);
    }
    if (removed > 0) {
      matches++;
      combo++;
      for (var i = 0; i < shelves.length; i++) {
        _resolveMatches(i);
      }
      _checkEnd();
    }
    return removed;
  }

  String? dominantType() {
    final map = <String, int>{};
    for (final s in shelves) {
      for (final slot in s.slots) {
        for (final item in slot.stack) {
          map[item.type] = (map[item.type] ?? 0) + 1;
        }
      }
    }
    if (map.isEmpty) return null;
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.first.key;
  }

  void addExtraShelf() {
    if (status != GameStatus.playing && status != GameStatus.lostSpace) return;
    if (shelves.any((s) => s.isTemporary && !s.isDock)) return;
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

  /// Goods Puzzle: watch ad for +60s when timer hits zero.
  void continueWithTime(int seconds) {
    if (status != GameStatus.lostTime) return;
    timeLeft = seconds;
    status = GameStatus.playing;
  }

  /// Goods Puzzle: watch ad for extra shelf when board locked.
  void continueWithExtraShelf() {
    if (status != GameStatus.lostSpace) return;
    addExtraShelf();
  }

  void _pushUndo() {
    _undo.add(
      _Snap(
        shelves: shelves
            .map(
              (s) => s.copyWith(
                slots: s.slots
                    .map(
                      (sl) => sl.copyWith(
                        stack: List<GameItem>.from(sl.stack),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
        moves: moves,
        matches: matches,
        combo: combo,
        timeLeft: timeLeft,
        mechanicState: Map<String, dynamic>.from(mechanics.saveState()),
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
        'maxCombo': maxCombo,
        'timeLeft': timeLeft,
        'frozen': frozen,
        'status': status.name,
        'mechanics': mechanics.saveState(),
      };

  void loadSaveJson(Map<String, dynamic> json) {
    shelves = (json['shelves'] as List)
        .map((e) => Shelf.fromJson(e as Map<String, dynamic>))
        .toList();
    moves = json['moves'] as int? ?? 0;
    matches = json['matches'] as int? ?? 0;
    combo = json['combo'] as int? ?? 0;
    maxCombo = json['maxCombo'] as int? ?? combo;
    timeLeft = json['timeLeft'] as int? ?? level.timeLimit;
    frozen = json['frozen'] as bool? ?? false;
    status = GameStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => GameStatus.playing,
    );
    final ms = json['mechanics'];
    if (ms is Map<String, dynamic>) {
      mechanics.loadState(ms);
    } else if (ms is Map) {
      mechanics.loadState(Map<String, dynamic>.from(ms));
    }
  }
}

class _Snap {
  final List<Shelf> shelves;
  final int moves;
  final int matches;
  final int combo;
  final int timeLeft;
  final Map<String, dynamic>? mechanicState;

  _Snap({
    required this.shelves,
    required this.moves,
    required this.matches,
    required this.combo,
    required this.timeLeft,
    this.mechanicState,
  });
}
