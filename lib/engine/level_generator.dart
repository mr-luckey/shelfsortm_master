import 'dart:math';

import '../models/level_data.dart';
import '../models/theme_room.dart';
import 'level_plan.dart';
import 'level_shapes.dart';
import 'mechanics/conveyor_tray.dart';
import 'mechanics/mechanic_ids.dart';

/// Data-driven level generator.
///
/// Board shape, type count, layers and time come from [LevelPlan]. Stocking
/// rules stay the same: each type appears exactly three times, most boxes are
/// full, and a few keep one place empty so goods can be carried around.
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

  /// Goods every level stocks — bottles, drinks, cakes and ice creams.
  ///
  /// Only artwork that owns a flat base is listed.
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
    'icecream',
    'softicecream',
    'shavedice',
    'popcorn',
    'bentobox',
    'takeoutbox',
    'bowlwithspoon',
    'steamingbowl',
    'potoffood',
    'fondue',
    'greensalad',
    'curryrice',
    'cookedrice',
    'oden',
    'sushi',
    'riceball',
    'dumpling',
    'hamburger',
    'frenchfries',
    'sandwich',
    'butter',
    'cheesewedge',
    'salt',
  ];

  static const int slotsPerShelf = 3;
  static const int maxLayers = 5;

  /// Goods a tray rolls in with, leaving one free place on it.
  static const int trayStock = 2;

  /// @deprecated Prefer [LevelPlan.forLevel]; kept for existing tests.
  static int flavorLevel(int levelId) =>
      ((levelId - 1) % ThemeRoom.levelsPerFlavor) + 1;

  static int layersFor(int levelId) => LevelPlan.forLevel(levelId).layers;

  static double hardnessFor(int levelId) {
    final plan = LevelPlan.forLevel(levelId);
    if (plan.layers <= 1 && levelId <= 5) return 0;
    final t = ((levelId - 1) % ThemeRoom.levelsPerFlavor) /
        (ThemeRoom.levelsPerFlavor - 1);
    return pow(t.clamp(0.0, 1.0), 0.62).toDouble();
  }

  static LevelData generate(int levelId) {
    final theme = ThemeRoom.forLevel(levelId);
    final difficulty = LevelDifficultyX.forLevel(levelId);
    final plan = LevelPlan.forLevel(levelId);
    final layout = LevelShapes.normalize(plan.layout);
    LevelShapes.validate(layout);
    final boxes = LevelShapes.boxCount(layout);
    final layers = plan.layers.clamp(1, maxLayers);
    final tint = tintColors[(levelId - 1) % tintColors.length];

    final trays = plan.trayCount.clamp(0, ConveyorTrayMechanic.maxTrays);
    final freeFrontTarget = boxes < 4 ? 2 : max(2, boxes ~/ 4);
    final maxTypesByCapacity =
        ((boxes * layers * slotsPerShelf + trays * trayStock - freeFrontTarget) ~/
                slotsPerShelf)
            .clamp(1, productTypes.length);

    // A board only holds so many sets; drop a type at a time until every set
    // of three actually fits, so no good is ever left unplaced.
    var typeCount = min(plan.typeCount, maxTypesByCapacity);
    List<InitialPlacement>? placements;
    while (typeCount >= 1 && placements == null) {
      placements = _stock(
        levelId: levelId,
        boxes: boxes,
        layers: layers,
        trays: trays,
        typeCount: typeCount,
        freeFrontTarget: freeFrontTarget,
        tint: tint,
      );
      if (placements == null) typeCount -= 1;
    }
    placements ??= const [];

    final optimal = (typeCount * 2.2).round() + boxes;
    final twoStar = (optimal * 1.35).round();
    final oneStar = (optimal * 1.8).round();

    // Big boards need a floor on the clock, otherwise a designed time can be
    // shorter than the moves the level actually asks for.
    final fairFloor = (placements.length * 3).ceil();
    final computedTime = max(
      plan.timeLimit ?? _timeFor(difficulty, placements.length, layers),
      fairFloor,
    );

    return LevelData(
      levelId: levelId,
      themeRoom: theme.id,
      difficulty: difficulty.name,
      timeLimit: computedTime,
      shelfCount: boxes,
      slotsPerShelf: slotsPerShelf,
      bufferShelves: boxes,
      initialPlacement: placements,
      optimalMoves: optimal,
      levelTint: tint,
      layout: layout,
      trayCount: trays,
      mechanics: [
        ...plan.mechanics,
        if (trays > 0) MechanicIds.conveyorTray,
      ],
      mechanicConfig: {
        ...plan.mechanicConfig,
        if (trays > 0)
          'conveyorTray': {
            'trayCount': trays,
            'speed': plan.traySpeed,
            'direction': plan.trayDirection,
          },
      },
      seed: levelId * 7919 + 17,
      starThresholds: StarThresholds(
        threeStar: optimal,
        twoStar: twoStar,
        oneStar: oneStar,
      ),
    );
  }

  /// Stocks [typeCount] sets of three onto the board, or null when they do not
  /// all fit under the free-space and no-instant-match rules.
  static List<InitialPlacement>? _stock({
    required int levelId,
    required int boxes,
    required int layers,
    required int trays,
    required int typeCount,
    required int freeFrontTarget,
    required String tint,
  }) {
    final rng = Random(levelId * 7919 + 17 + typeCount);

    // Trays come first so the belt always rolls in loaded; then the visible
    // cupboard row, then the layers stacked behind it.
    final cells = <({int shelfId, int depth})>[];
    for (var t = 0; t < trays; t++) {
      cells.add((shelfId: boxes + 1 + t, depth: 0));
    }
    for (var d = 0; d < layers; d++) {
      for (var b = 1; b <= boxes; b++) {
        cells.add((shelfId: b, depth: d));
      }
    }

    final types = List<String>.from(productTypes)..shuffle(rng);
    final usedTypes = types.take(typeCount).toList();

    // A set either stands two-together with its third elsewhere, or is split
    // into three loose goods on harder levels.
    final hardness = hardnessFor(levelId);
    final chunks = <List<String>>[];
    for (final type in usedTypes) {
      if (rng.nextDouble() < hardness) {
        chunks
          ..add([type])
          ..add([type])
          ..add([type]);
      } else {
        chunks
          ..add([type, type])
          ..add([type]);
      }
    }
    chunks.shuffle(rng);

    final itemTotal = typeCount * 3;
    final capacity =
        trays * trayStock + (cells.length - trays) * slotsPerShelf;
    if (capacity - itemTotal < freeFrontTarget) return null;

    // A few front boxes keep one place empty so goods can be carried around;
    // those places are spread evenly across the visible row.
    final gapBoxes = <int>{};
    final gapCount = max(freeFrontTarget, boxes ~/ 4).clamp(1, boxes);
    for (var k = 0; k < gapCount; k++) {
      final at = (((k + 1) * boxes) ~/ (gapCount + 1)).clamp(0, boxes - 1);
      gapBoxes.add(at);
    }

    // Trays roll in part-loaded so there is always somewhere to put a good;
    // front boxes with a reserved place hold one good less.
    final room = [
      for (var i = 0; i < cells.length; i++)
        if (i < trays)
          trayStock
        else if (i - trays < boxes && gapBoxes.contains(i - trays))
          slotsPerShelf - 1
        else
          slotsPerShelf,
    ];

    final stocked = List.generate(cells.length, (_) => <String>[]);

    bool fits(int index, List<String> chunk) {
      if (stocked[index].length + chunk.length > room[index]) return false;
      // A full box of three of a kind would already be sold.
      final same = stocked[index].where((t) => t == chunk.first).length;
      if (room[index] >= slotsPerShelf &&
          same + chunk.length >= slotsPerShelf) {
        return false;
      }
      return true;
    }

    // Two-together sets are stocked first so they get the roomier places.
    chunks.sort((a, b) => b.length.compareTo(a.length));
    for (final chunk in chunks) {
      var placed = false;
      for (var i = 0; i < cells.length && !placed; i++) {
        if (!fits(i, chunk)) continue;
        stocked[i].addAll(chunk);
        placed = true;
      }
      if (!placed) return null;
    }

    var frontFree = 0;
    for (var i = trays; i < trays + boxes; i++) {
      frontFree += slotsPerShelf - stocked[i].length;
    }
    if (frontFree < freeFrontTarget) return null;

    var counter = 0;
    final placements = <InitialPlacement>[];
    for (var i = 0; i < cells.length; i++) {
      final stock = stocked[i]..shuffle(rng);
      if (stock.isEmpty) continue;
      final cell = cells[i];
      // Which place stays empty moves around: left, middle or right.
      final places = [for (var s = 0; s < slotsPerShelf; s++) s]..shuffle(rng);
      final used = places.take(stock.length).toList()..sort();
      for (var k = 0; k < stock.length; k++) {
        counter += 1;
        placements.add(
          InitialPlacement(
            itemId:
                '${stock[k]}_${tint}_${counter.toString().padLeft(3, '0')}',
            shelfId: cell.shelfId,
            slot: used[k],
            depth: cell.depth,
          ),
        );
      }
    }
    return placements;
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
