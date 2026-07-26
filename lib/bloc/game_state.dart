import 'package:equatable/equatable.dart';

import '../engine/match_engine.dart';
import '../models/item.dart';
import '../models/level_data.dart';
import '../models/shelf.dart';

class GameState extends Equatable {
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
  final int clearingShelf;
  final bool ready;
  final BoardPos? selected;

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
    this.ready = false,
    this.selected,
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

  int get stars =>
      level?.starThresholds.starsForTimeLeft(timeLeft, level!.timeLimit) ?? 1;

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
    bool? ready,
    BoardPos? selected,
    bool clearBanner = false,
    bool clearSelected = false,
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
      ready: ready ?? this.ready,
      selected: clearSelected ? null : (selected ?? this.selected),
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
        ready,
        selected,
      ];
}
