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

  /// Goods every level stocks right now — bottles, drinks, cakes and ice
  /// creams, so one screen reads like a single shop aisle.
  static const productTypes = [
    'babybottle',
    'beveragebox',
    'bubbletea',
    'cupwithstraw',
    'glassofmilk',
    'hotbeverage',
    'teacupwithouthandle',
    'teapot',
    'tropicaldrink',
    'mate',
    'cannedfood',
    'honeypot',
    'jar',
    'amphora',
    'birthdaycake',
    'shortcake',
    'cupcake',
    'mooncake',
    'pie',
    'custard',
    'pancakes',
    'waffle',
    'croissant',
    'icecream',
    'softicecream',
    'shavedice',
    'cookie',
    'fortunecookie',
    'candy',
    'lollipop',
    'chocolatebar',
    'doughnut',
    'dango',
    'pretzel',
    'popcorn',
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

  /// Columns the board is laid out in — fixed for every level.
  static const int columns = 4;

  /// Boxes used when the caller has not measured the board yet.
  static const int defaultBoxes = 20;

  static LevelData generate(int levelId, {int boxes = defaultBoxes}) {
    final theme = ThemeRoom.forLevel(levelId);
    final difficulty = LevelDifficultyX.forLevel(levelId);
    final rng = Random(levelId * 7919 + 17);

    final layers = layersFor(levelId);
    final tint = tintColors[(levelId - 1) % tintColors.length];

    // Front layer first so any shortfall falls off the deepest layer instead.
    final cells = <({int shelfId, int depth})>[];
    for (var d = 0; d < layers; d++) {
      for (var b = 1; b <= boxes; b++) {
        cells.add((shelfId: b, depth: d));
      }
    }

    // A box keeps one spot free per layer, so a cell holds two goods. Exactly
    // three of a kind exist per screen, which is what caps the type count.
    final typeCount = min(
      (cells.length * (slotsPerShelf - 1)) ~/ 3,
      productTypes.length,
    );
    final types = List<String>.from(productTypes)..shuffle(rng);
    final usedTypes = types.take(typeCount).toList();

    // Stocked like a real shelf: two of a kind stand side by side and the
    // third waits in another box. Later levels split all three apart.
    final hardness = hardnessFor(levelId);
    final pairs = <String>[];
    final singles = <String>[];
    for (final type in usedTypes) {
      if (rng.nextDouble() < hardness) {
        singles.addAll([type, type, type]);
      } else {
        pairs.add(type);
        singles.add(type);
      }
    }
    singles.shuffle(rng);

    final cellPlans = <List<String>>[
      for (final type in pairs) [type, type],
      for (var i = 0; i < singles.length; i += 2)
        singles.sublist(i, min(i + 2, singles.length)),
    ]..shuffle(rng);

    var counter = 0;
    final placements = <InitialPlacement>[];
    for (var i = 0; i < cellPlans.length && i < cells.length; i++) {
      final cell = cells[i];
      final free = rng.nextInt(slotsPerShelf);
      var slot = 0;
      for (final type in cellPlans[i]) {
        if (slot == free) slot += 1;
        counter += 1;
        placements.add(
          InitialPlacement(
            itemId: '${type}_${tint}_${counter.toString().padLeft(3, '0')}',
            shelfId: cell.shelfId,
            slot: slot,
            depth: cell.depth,
          ),
        );
        slot += 1;
      }
    }

    final itemCount = placements.length;
    final triples = typeCount;

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
