import '../engine/level_generator.dart';
import '../models/level_data.dart';
import '../models/player_progress.dart';

class LevelRepository {
  LevelRepository._();
  static final LevelRepository instance = LevelRepository._();

  /// Levels are pure functions of their id, so they are built on demand and
  /// only the few most recently played are kept around.
  static const int _cacheLimit = 8;

  final Map<String, LevelData> _cache = {};

  int get totalLevels => PlayerProgress.totalLevels;

  /// Nothing to load up front — generation happens lazily in [getLevel].
  Future<void> preload() async {}

  /// [boxes] is how many cubbies the board fits on this screen.
  LevelData getLevel(int levelId, {int boxes = LevelGenerator.defaultBoxes}) {
    final key = '$levelId:$boxes';
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached; // refresh recency
      return cached;
    }
    final level = LevelGenerator.generate(levelId, boxes: boxes);
    _cache[key] = level;
    while (_cache.length > _cacheLimit) {
      _cache.remove(_cache.keys.first);
    }
    return level;
  }

  LevelData dailyChallenge(
    DateTime date, {
    int boxes = LevelGenerator.defaultBoxes,
  }) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final base = LevelGenerator.generate((seed % 200) + 8, boxes: boxes);
    return LevelData(
      levelId: 9000 + (seed % 1000),
      themeRoom: base.themeRoom,
      difficulty: 'hard',
      timeLimit: (base.timeLimit * 0.9).round(),
      shelfCount: base.shelfCount,
      slotsPerShelf: 3,
      bufferShelves: base.bufferShelves,
      initialPlacement: base.initialPlacement,
      optimalMoves: base.optimalMoves,
      levelTint: base.levelTint,
      layout: base.layout,
      mechanics: base.mechanics,
      mechanicConfig: base.mechanicConfig,
      seed: seed,
      starThresholds: base.starThresholds,
    );
  }
}
