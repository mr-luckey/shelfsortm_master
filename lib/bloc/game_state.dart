import 'package:equatable/equatable.dart';

import '../engine/match_engine.dart';
import '../models/item.dart';
import '../models/level_data.dart';
import '../models/shelf.dart';

class GameState extends Equatable {
  static const int freezesPerLevel = 3;
  static const int hintsPerLevel = 3;

  final LevelData? level;
  final List<Shelf> shelves;
  final List<GameItem?> belt;
  final int reserveCount;
  final int moves;
  final int matches;
  final int combo;
  final int timeLeft;
  final bool frozen;
  final GameStatus status;
  final MatchClear? lastClear;
  final String? banner;
  /// First box playing its sale, kept for the older board widgets.
  final int clearingShelf;

  /// Every box playing its sale right now.
  final Set<int> clearingShelves;
  final int openingShelf;
  final bool inputLocked;
  final Set<int> finishedShelves;
  final bool ready;
  final BoardPos? selected;
  final List<String> activeMechanics;
  final String? objectiveHint;
  final int maxCombo;
  final Map<String, dynamic> mechanicVisual;

  /// Layer waiting behind each box, drawn as a shadow. Null = nothing behind.
  final List<List<GameItem?>?> nextLayers;

  /// Remaining Freeze uses this level (starts at [freezesPerLevel]).
  final int freezesLeft;

  /// Remaining Hint uses this level (starts at [hintsPerLevel]).
  final int hintsLeft;

  /// Hint guide: pick up this front…
  final BoardPos? hintFrom;

  /// …and drop it on this empty slot.
  final BoardPos? hintTo;

  const GameState({
    this.level,
    this.shelves = const [],
    this.belt = const [],
    this.reserveCount = 0,
    this.moves = 0,
    this.matches = 0,
    this.combo = 0,
    this.timeLeft = 0,
    this.frozen = false,
    this.status = GameStatus.ready,
    this.lastClear,
    this.banner,
    this.clearingShelf = -1,
    this.clearingShelves = const {},
    this.openingShelf = -1,
    this.inputLocked = false,
    this.finishedShelves = const {},
    this.ready = false,
    this.selected,
    this.activeMechanics = const [],
    this.objectiveHint,
    this.maxCombo = 0,
    this.mechanicVisual = const {},
    this.nextLayers = const [],
    this.freezesLeft = 0,
    this.hintsLeft = 0,
    this.hintFrom,
    this.hintTo,
  });

  int get itemCount {
    var n = reserveCount;
    for (final b in belt) {
      if (b != null) n++;
    }
    for (final s in shelves) {
      n += s.occupiedCount;
    }
    return n;
  }

  int get stars {
    if (level == null) return 1;
    return level!.starThresholds.starsForTimeLeft(timeLeft, level!.timeLimit);
  }

  bool get isTerminal =>
      status == GameStatus.won ||
      status == GameStatus.lostTime ||
      status == GameStatus.lostSpace;

  GameState copyWith({
    LevelData? level,
    List<Shelf>? shelves,
    List<GameItem?>? belt,
    int? reserveCount,
    int? moves,
    int? matches,
    int? combo,
    int? timeLeft,
    bool? frozen,
    GameStatus? status,
    MatchClear? lastClear,
    String? banner,
    int? clearingShelf,
    Set<int>? clearingShelves,
    int? openingShelf,
    bool? inputLocked,
    Set<int>? finishedShelves,
    bool? ready,
    BoardPos? selected,
    List<String>? activeMechanics,
    String? objectiveHint,
    int? maxCombo,
    Map<String, dynamic>? mechanicVisual,
    List<List<GameItem?>?>? nextLayers,
    int? freezesLeft,
    int? hintsLeft,
    BoardPos? hintFrom,
    BoardPos? hintTo,
    bool clearBanner = false,
    bool clearSelected = false,
    bool clearObjective = false,
    bool clearHint = false,
  }) {
    return GameState(
      level: level ?? this.level,
      shelves: shelves ?? this.shelves,
      belt: belt ?? this.belt,
      reserveCount: reserveCount ?? this.reserveCount,
      moves: moves ?? this.moves,
      matches: matches ?? this.matches,
      combo: combo ?? this.combo,
      timeLeft: timeLeft ?? this.timeLeft,
      frozen: frozen ?? this.frozen,
      status: status ?? this.status,
      lastClear: lastClear ?? this.lastClear,
      banner: clearBanner ? null : (banner ?? this.banner),
      clearingShelf: clearingShelf ?? this.clearingShelf,
      clearingShelves: clearingShelves ?? this.clearingShelves,
      openingShelf: openingShelf ?? this.openingShelf,
      inputLocked: inputLocked ?? this.inputLocked,
      finishedShelves: finishedShelves ?? this.finishedShelves,
      ready: ready ?? this.ready,
      selected: clearSelected ? null : (selected ?? this.selected),
      activeMechanics: activeMechanics ?? this.activeMechanics,
      objectiveHint:
          clearObjective ? null : (objectiveHint ?? this.objectiveHint),
      maxCombo: maxCombo ?? this.maxCombo,
      mechanicVisual: mechanicVisual ?? this.mechanicVisual,
      nextLayers: nextLayers ?? this.nextLayers,
      freezesLeft: freezesLeft ?? this.freezesLeft,
      hintsLeft: hintsLeft ?? this.hintsLeft,
      hintFrom: clearHint ? null : (hintFrom ?? this.hintFrom),
      hintTo: clearHint ? null : (hintTo ?? this.hintTo),
    );
  }

  @override
  List<Object?> get props => [
        level?.levelId,
        shelves,
        belt,
        reserveCount,
        moves,
        matches,
        combo,
        timeLeft,
        frozen,
        status,
        lastClear,
        banner,
        clearingShelf,
        clearingShelves,
        openingShelf,
        inputLocked,
        finishedShelves,
        ready,
        selected,
        activeMechanics,
        objectiveHint,
        maxCombo,
        mechanicVisual,
        nextLayers,
        freezesLeft,
        hintsLeft,
        hintFrom,
        hintTo,
      ];
}
