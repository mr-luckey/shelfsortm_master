import 'dart:math';

import '../models/level_data.dart';
import '../models/theme_room.dart';

/// Layered Sort Challenge generator.
///
/// Every flavor repeats the same 1–100 curve:
/// - a box holds 3 spots and always keeps exactly one of them free
/// - level 1 is a single layer, each further level adds one more layer behind
///   it (up to [maxLayers])
/// - a layer stays hidden until the box in front of it is emptied
/// - nothing is ever spawned beyond the layers the level starts with
///
/// The cupboard never changes shape: the board fills the screen and the caller
/// passes how many boxes fit, so only depth and scatter scale with the level.
class LevelGenerator {
  static const tintColors = [
    'red',
    'blue',
    'green',
    'yellow',
    'purple',
    'orange',
    'pink',
    'teal',
  ];

  /// Slots in one box. Exactly one of them stays empty per layer.
  static const int slotsPerShelf = 3;

  /// Deepest stack a box can hold; layers grow one per level up to this.
  static const int maxLayers = 5;

  /// Position of [levelId] inside its flavor (1–100).
  static int flavorLevel(int levelId) =>
      ((levelId - 1) % ThemeRoom.levelsPerFlavor) + 1;

  /// Layers behind each box front for [levelId].
  static int layersFor(int levelId) =>
      flavorLevel(levelId).clamp(1, maxLayers);

  /// How far apart a set of three starts out: 0 at level 1 (already grouped,
  /// one move from a match) rising to 1 at level 100 (fully scattered).
  static double hardnessFor(int levelId) {
    final span = ThemeRoom.levelsPerFlavor - 1;
    if (span <= 0) return 0;
    final t = (flavorLevel(levelId) - 1) / span;
    // Ramps quickly over the first levels, then keeps climbing to 1.0.
    return pow(t, 0.62).toDouble();
  }

  /// Window-limited shuffle: an item can only drift [hardness] * length places,
  /// so 0 keeps every set of three together and 1 is a full shuffle.
  static void _scramble(List<String> items, double hardness, Random rng) {
    final n = items.length;
    if (n < 2) return;
    final h = hardness.clamp(0.0, 1.0);
    final window = (h * n).round();
    if (window < 1) return;
    for (var i = 0; i < n; i++) {
      final j = i + rng.nextInt(min(window, n - i));
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }

  /// Columns the board is laid out in — fixed for every level.
  static const int columns = 4;

  /// Boxes used when the caller has not measured the board yet.
  static const int defaultBoxes = 20;

  static LevelData generate(int levelId, {int boxes = defaultBoxes}) {
    final theme = ThemeRoom.forLevel(levelId);
    final difficulty = LevelDifficultyX.forLevel(levelId);
    final n = flavorLevel(levelId);
    final rng = Random(levelId * 7919 + 17);

    final layers = layersFor(levelId);
    final tint = tintColors[(levelId - 1) % tintColors.length];

    // One free spot per box per layer keeps the board from ever deadlocking.
    final capacity = boxes * layers * (slotsPerShelf - 1);
    final itemCount = (capacity ~/ 3) * 3;
    final triples = itemCount ~/ 3;

    final typeCap = min(triples, theme.itemTypes.length);
    final int typeCount = max(1, min(_typeCountFor(n), typeCap));
    final types = List<String>.from(theme.itemTypes)..shuffle(rng);
    final usedTypes = types.take(typeCount).toList();

    final triplesPerType = List<int>.filled(typeCount, 0);
    for (var i = 0; i < triples; i++) {
      triplesPerType[i % typeCount] += 1;
    }

    // Built grouped: every set of three sits together, so an untouched board
    // is one move from a match. Scrambling below pulls those sets apart.
    final items = <String>[];
    var counter = 0;
    for (var t = 0; t < typeCount; t++) {
      for (var k = 0; k < triplesPerType[t] * 3; k++) {
        counter += 1;
        items.add('${usedTypes[t]}_${tint}_${counter.toString().padLeft(3, '0')}');
      }
    }
    _scramble(items, hardnessFor(levelId), rng);

    // Front layer first so any shortfall falls off the deepest layer instead.
    final spots = <({int shelfId, int slot, int depth})>[];
    for (var d = 0; d < layers; d++) {
      for (var b = 1; b <= boxes; b++) {
        final free = rng.nextInt(slotsPerShelf);
        for (var s = 0; s < slotsPerShelf; s++) {
          if (s == free) continue;
          spots.add((shelfId: b, slot: s, depth: d));
        }
      }
    }

    final placements = <InitialPlacement>[
      for (var i = 0; i < items.length && i < spots.length; i++)
        InitialPlacement(
          itemId: items[i],
          shelfId: spots[i].shelfId,
          slot: spots[i].slot,
          depth: spots[i].depth,
        ),
    ];

    final optimal = (triples * 2.2).round() + boxes;
    final twoStar = (optimal * 1.35).round();
    final oneStar = (optimal * 1.8).round();

    return LevelData(
      levelId: levelId,
      themeRoom: theme.id,
      difficulty: difficulty.name,
      timeLimit: _timeFor(difficulty, itemCount, layers),
      shelfCount: boxes,
      slotsPerShelf: slotsPerShelf,
      bufferShelves: boxes,
      initialPlacement: placements,
      optimalMoves: optimal,
      levelTint: tint,
      layout: _rowMajorLayout(boxes),
      seed: levelId * 7919 + 17,
      starThresholds: StarThresholds(
        threeStar: optimal,
        twoStar: twoStar,
        oneStar: oneStar,
      ),
    );
  }

  /// Shelf ids 1..[boxes] packed into rows of [columns].
  static List<List<int>> _rowMajorLayout(int boxes) {
    final grid = <List<int>>[];
    for (var i = 0; i < boxes; i += columns) {
      grid.add([for (var c = i; c < min(i + columns, boxes); c++) c + 1]);
    }
    return grid;
  }

  /// Distinct emoji types on the board — more variety as the flavor advances.
  static int _typeCountFor(int flavorLevel) {
    if (flavorLevel <= 2) return 2;
    if (flavorLevel <= 5) return 3;
    if (flavorLevel <= 12) return 4;
    if (flavorLevel <= 25) return 5;
    if (flavorLevel <= 45) return 6;
    if (flavorLevel <= 70) return 7;
    return 8;
  }

  static int _timeFor(LevelDifficulty d, int itemCount, int layers) {
    final base = (itemCount * (3.2 + layers * 0.4)).round() + 55;
    switch (d) {
      case LevelDifficulty.easy:
      case LevelDifficulty.rest:
        return (base * 1.55).round().clamp(100, 900);
      case LevelDifficulty.hard:
        return (base * 1.05).round().clamp(80, 900);
      case LevelDifficulty.tricky:
        return base.clamp(75, 900);
      case LevelDifficulty.boss:
        return (base * 0.95).round().clamp(110, 900);
      case LevelDifficulty.standard:
        return (base * 1.2).round().clamp(90, 900);
    }
  }
}
