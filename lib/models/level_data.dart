import 'item.dart';
import 'shelf.dart';
import 'theme_room.dart';

class InitialPlacement {
  final String itemId;
  final int shelfId;
  final int slot;
  /// 0 = front, higher = further behind.
  final int depth;

  const InitialPlacement({
    required this.itemId,
    required this.shelfId,
    required this.slot,
    this.depth = 0,
  });

  factory InitialPlacement.fromJson(Map<String, dynamic> json) =>
      InitialPlacement(
        itemId: json['itemId'] as String,
        shelfId: json['shelfId'] as int,
        slot: json['slot'] as int,
        depth: json['depth'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'shelfId': shelfId,
        'slot': slot,
        if (depth != 0) 'depth': depth,
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
  final List<String> queue;
  final int dockSlots;
  /// Mono tint for all goods this level (Falcon color-theme levels).
  final String levelTint;
  /// Irregular cabinet: each row is shelfIds (1-based), 0 = visual gap.
  final List<List<int>> layout;
  /// Active dynamic mechanics for this level (PRD §6A).
  final List<String> mechanics;
  /// Per-mechanic configuration keyed by camelCase mechanic name.
  final Map<String, dynamic> mechanicConfig;
  /// Deterministic seed for animated / random mechanics.
  final int seed;

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
    this.levelTint = 'orange',
    this.layout = const [],
    this.mechanics = const [],
    this.mechanicConfig = const {},
    this.seed = 0,
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

    List<List<int>> layout = [];
    if (json['layout'] is List) {
      layout = (json['layout'] as List)
          .map((row) => (row as List).map((e) => e as int).toList())
          .toList();
    }

    Map<String, dynamic> mechanicConfig = {};
    if (json['mechanicConfig'] is Map) {
      mechanicConfig =
          Map<String, dynamic>.from(json['mechanicConfig'] as Map);
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
      levelTint: json['levelTint'] as String? ?? 'orange',
      layout: layout,
      mechanics: (json['mechanics'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      mechanicConfig: mechanicConfig,
      seed: json['seed'] as int? ?? (json['levelId'] as int? ?? 0),
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
        'levelTint': levelTint,
        'layout': layout,
        'initialPlacement': initialPlacement.map((e) => e.toJson()).toList(),
        'optimalMoves': optimalMoves,
        'starThresholds': starThresholds.toJson(),
        if (mechanics.isNotEmpty) 'mechanics': mechanics,
        if (mechanicConfig.isNotEmpty) 'mechanicConfig': mechanicConfig,
        if (seed != 0) 'seed': seed,
      };

  /// Stars based on moves used (PRD §7.2). Falls back to time-based if needed.
  int starsForMoves(int moves) {
    if (optimalMoves > 0) {
      if (moves <= starThresholds.threeStar || moves <= optimalMoves) {
        return 3;
      }
      if (moves <= starThresholds.twoStar ||
          moves <= (optimalMoves * 1.2).ceil()) {
        return 2;
      }
      return 1;
    }
    return starThresholds.starsForTimeLeft(
      // Approximate leftover quality from move efficiency
      (optimalMoves > 0 ? (optimalMoves - moves).clamp(0, 999) : 30),
      optimalMoves > 0 ? optimalMoves : 60,
    );
  }

  /// Board at level start: only layer 0 (depth 0) is on the shelves. Deeper
  /// layers are held by [ShelfWaveManager] and slide forward when a box empties.
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
      if (p.depth != 0) continue;
      final idx = board.indexWhere((s) => s.shelfId == p.shelfId);
      if (idx < 0) continue;
      if (p.slot < 0 || p.slot >= board[idx].slots.length) continue;
      board[idx] = board[idx].withSlot(
        p.slot,
        ShelfSlot.front(GameItem.fromId(p.itemId)),
      );
    }
    return board;
  }

  List<Shelf> buildPlayShelves() => buildSortedChallengeBoard();
  List<Shelf> buildEmptyShelves() => buildSortedChallengeBoard();

  /// Fallback layout if JSON has none: Falcon-style irregular rows.
  List<List<int>> resolvedLayout() {
    if (layout.isNotEmpty) return layout;
    return defaultLayout(shelfCount);
  }

  static List<List<int>> defaultLayout(int n) {
    if (n <= 0) return [];
    if (n <= 4) {
      var id = 1;
      final first = List.generate(n >= 2 ? 2 : n, (_) => id++);
      final rest = <int>[];
      while (id <= n) {
        rest.add(id++);
      }
      return rest.isEmpty ? [first] : [first, rest];
    }
    if (n <= 6) {
      var id = 1;
      return [
        List.generate(2, (_) => id++),
        List.generate(2, (_) => id++),
        List.generate(n - 4, (_) => id++),
      ];
    }
    // Pick column width by board size
    final cols = n <= 9
        ? 3
        : n <= 12
            ? 3
            : n <= 20
                ? 4
                : 5;
    var id = 1;
    final rows = <List<int>>[];
    while (id <= n) {
      final left = n - id + 1;
      final take = left >= cols ? cols : left;
      rows.add(List.generate(take, (_) => id++));
    }
    return rows;
  }
}
