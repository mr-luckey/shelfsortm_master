import 'item.dart';
import 'shelf.dart';
import 'theme_room.dart';

class InitialPlacement {
  final String itemId;
  final int shelfId;
  final int slot;

  const InitialPlacement({
    required this.itemId,
    required this.shelfId,
    required this.slot,
  });

  factory InitialPlacement.fromJson(Map<String, dynamic> json) =>
      InitialPlacement(
        itemId: json['itemId'] as String,
        shelfId: json['shelfId'] as int,
        slot: json['slot'] as int,
      );

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'shelfId': shelfId,
        'slot': slot,
      };
}

class StarThresholds {
  final int threeStar;
  final int twoStar;
  final int oneStar;

  const StarThresholds({
    required this.threeStar,
    required this.twoStar,
    this.oneStar = 0,
  });

  factory StarThresholds.fromJson(Map<String, dynamic> json) => StarThresholds(
        threeStar: json['3star'] as int,
        twoStar: json['2star'] as int,
        oneStar: json['1star'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        '3star': threeStar,
        '2star': twoStar,
        '1star': oneStar,
      };

  int starsForTimeLeft(int timeLeft, int timeLimit) {
    if (timeLimit <= 0) return 3;
    final ratio = timeLeft / timeLimit;
    if (ratio >= 0.45 || timeLeft >= threeStar) return 3;
    if (ratio >= 0.2 || timeLeft >= twoStar) return 2;
    return 1;
  }
}

class LevelData {
  final int levelId;
  final String themeRoom;
  final String difficulty;
  final int timeLimit;
  final int shelfCount;
  final int slotsPerShelf;
  final int bufferShelves;
  final List<InitialPlacement> initialPlacement;
  final StarThresholds starThresholds;
  final int optimalMoves;
  final List<String> queue; // unused in sort challenge; kept for compat
  final int dockSlots;

  const LevelData({
    required this.levelId,
    required this.themeRoom,
    required this.difficulty,
    required this.timeLimit,
    required this.shelfCount,
    required this.slotsPerShelf,
    required this.initialPlacement,
    required this.starThresholds,
    this.bufferShelves = 2,
    this.optimalMoves = 0,
    this.queue = const [],
    this.dockSlots = 0,
  });

  ThemeRoom get theme => ThemeRoom.byId(themeRoom);

  LevelDifficulty get difficultyEnum {
    switch (difficulty) {
      case 'easy':
        return LevelDifficulty.easy;
      case 'hard':
        return LevelDifficulty.hard;
      case 'tricky':
        return LevelDifficulty.tricky;
      case 'boss':
        return LevelDifficulty.boss;
      case 'rest':
        return LevelDifficulty.rest;
      default:
        return LevelDifficulty.standard;
    }
  }

  factory LevelData.fromJson(Map<String, dynamic> json) {
    List<InitialPlacement> placements = [];
    if (json['initialPlacement'] is List) {
      placements = (json['initialPlacement'] as List)
          .map((e) => InitialPlacement.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return LevelData(
      levelId: json['levelId'] as int,
      themeRoom: json['themeRoom'] as String,
      difficulty: json['difficulty'] as String? ?? 'standard',
      timeLimit: json['timeLimit'] as int? ?? 120,
      shelfCount: json['shelfCount'] as int? ?? 6,
      slotsPerShelf: json['slotsPerShelf'] as int? ?? 3,
      bufferShelves: json['bufferShelves'] as int? ?? 2,
      initialPlacement: placements,
      optimalMoves: json['optimalMoves'] as int? ?? 0,
      queue: (json['queue'] as List?)?.map((e) => e as String).toList() ?? [],
      dockSlots: json['dockSlots'] as int? ?? 0,
      starThresholds: json['starThresholds'] != null
          ? StarThresholds.fromJson(
              json['starThresholds'] as Map<String, dynamic>,
            )
          : const StarThresholds(threeStar: 40, twoStar: 15),
    );
  }

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'themeRoom': themeRoom,
        'difficulty': difficulty,
        'timeLimit': timeLimit,
        'shelfCount': shelfCount,
        'slotsPerShelf': slotsPerShelf,
        'bufferShelves': bufferShelves,
        'initialPlacement': initialPlacement.map((e) => e.toJson()).toList(),
        'optimalMoves': optimalMoves,
        'starThresholds': starThresholds.toJson(),
      };

  /// Sort Challenge cabinet: shelves with placements, some fully empty buffers.
  List<Shelf> buildSortedChallengeBoard() {
    final board = List.generate(
      shelfCount,
      (i) => Shelf(
        shelfId: i + 1,
        slotCount: slotsPerShelf,
        slots: List.generate(slotsPerShelf, (_) => const ShelfSlot()),
      ),
    );

    for (final p in initialPlacement) {
      final idx = board.indexWhere((s) => s.shelfId == p.shelfId);
      if (idx < 0) continue;
      if (p.slot < 0 || p.slot >= board[idx].slots.length) continue;
      board[idx] = board[idx].withSlot(
        p.slot,
        ShelfSlot(item: GameItem.fromId(p.itemId)),
      );
    }
    return board;
  }

  List<Shelf> buildPlayShelves() => buildSortedChallengeBoard();
  List<Shelf> buildEmptyShelves() => buildSortedChallengeBoard();
}
