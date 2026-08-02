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

  /// Most goods a single level ever stocks, so even the deepest board stays a
  /// board a player can finish rather than an endless shift.
  static const int maxStock = 240;

  /// Goods a tray rolls in with on its front layer. Trays alternate so roughly
  /// half of the belt always has a free place to drop a good onto.
  static int trayRoom(int ordinal) => ordinal.isEven ? 3 : 2;

  /// @deprecated Prefer [LevelPlan.forLevel]; kept for existing tests.
  static int flavorLevel(int levelId) =>
      ((levelId - 1) % ThemeRoom.levelsPerFlavor) + 1;

  /// Deepest a box may stack on this level.
  static int layersFor(int levelId) => LevelPlan.forLevel(levelId).layers;

  /// How often a set of three starts scattered as three loose goods instead of
  /// a helpful pair plus a single. Climbs across the 30 level campaign.
  static double hardnessFor(int levelId) {
    if (levelId <= 3) return 0;
    final t = ((levelId - 3) / (LevelPlan.lastLevel - 3)).clamp(0.0, 1.0);
    return pow(t, 0.7).toDouble();
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
    final trayLayers = plan.trayLayers.clamp(1, maxLayers);
    // Free places in the front row. Early boards keep a couple more to learn
    // in; later boards keep only the working room they need.
    final freeFrontTarget = boxes <= 4
        ? max(2, boxes ~/ 2)
        : levelId <= 10
            ? max(3, (boxes / 5).ceil())
            : max(3, (boxes / 7).ceil());

    var trayFront = 0;
    for (var t = 0; t < trays; t++) {
      trayFront += trayRoom(t);
    }

    // The front row is stocked full — three goods a box, a handful of boxes
    // with two — so the cupboard always looks shopped, never bare. Everything
    // the plan hides goes into the layers behind that front row.
    final front = boxes * slotsPerShelf - freeFrontTarget;
    final deepCapacity = boxes * slotsPerShelf * (layers - 1) +
        trays * 2 * (trayLayers - 1);
    final deepRoom = max(0, maxStock - front - trayFront);
    final deep = min(min(plan.hidden, deepCapacity), deepRoom);
    final goods = front + trayFront + deep;

    // Sets of three; a set may repeat a product family once every family has
    // been used, which is what makes the late boards so easy to misread.
    var sets = goods ~/ slotsPerShelf;
    List<InitialPlacement>? placements;
    while (sets >= 1 && placements == null) {
      placements = _stock(
        levelId: levelId,
        boxes: boxes,
        layers: layers,
        trays: trays,
        trayLayers: trayLayers,
        sets: sets,
        deepShare: goods == 0 ? 0 : deep / goods,
        freeFrontTarget: freeFrontTarget,
        tint: tint,
      );
      if (placements == null) sets -= 1;
    }
    placements ??= const [];

    final optimal = (sets * 2.2).round() + boxes;
    final twoStar = (optimal * 1.35).round();
    final oneStar = (optimal * 1.8).round();

    // The clock comes from the plan's seconds-per-good, with a floor so a board
    // is never shorter than the moves it actually asks for.
    final designed = plan.timeLimit ??
        (placements.length * plan.secPerGood).round();
    final fairFloor = (placements.length * 1.6).ceil();
    final computedTime = max(designed, fairFloor).clamp(60, 480);

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

  /// Stocks [sets] sets of three onto the board, or null when they do not all
  /// fit under the free-space and no-instant-match rules.
  ///
  /// Depth is decided box by box: one box may hide three layers behind its
  /// front row while its neighbour hides none, and the same goes for the trays.
  /// Every box and every tray still starts with at least one good in it.
  static List<InitialPlacement>? _stock({
    required int levelId,
    required int boxes,
    required int layers,
    required int trays,
    required int trayLayers,
    required int sets,
    required double deepShare,
    required int freeFrontTarget,
    required String tint,
  }) {
    final goods = sets * slotsPerShelf;
    if (goods < boxes + trays) return null;

    for (var attempt = 0; attempt < 40; attempt++) {
      final rng = Random(levelId * 7919 + 17 + sets * 31 + attempt * 977);
      final cells = _fillPlan(
        rng: rng,
        boxes: boxes,
        layers: layers,
        trays: trays,
        trayLayers: trayLayers,
        goods: goods,
        deepShare: deepShare,
        freeFrontTarget: freeFrontTarget,
      );
      if (cells == null) return null;
      final placements = _assign(
        rng: rng,
        levelId: levelId,
        cells: cells,
        sets: sets,
        tint: tint,
      );
      if (placements != null) return placements;
    }
    return null;
  }

  /// One entry per stocked cell: which box or tray, how deep, and how many
  /// goods it holds.
  static List<({int shelfId, int depth, int count})>? _fillPlan({
    required Random rng,
    required int boxes,
    required int layers,
    required int trays,
    required int trayLayers,
    required int goods,
    required double deepShare,
    required int freeFrontTarget,
  }) {
    var trayFront = 0;
    final trayFrontCount = <int>[];
    for (var t = 0; t < trays; t++) {
      trayFrontCount.add(trayRoom(t));
      trayFront += trayRoom(t);
    }
    if (goods - trayFront < 2 * boxes) return null;

    final frontCap = boxes * slotsPerShelf - freeFrontTarget;
    // The front row is stocked first and stays as full as the free-space target
    // allows; only what is left over hides in the layers behind. That way a
    // cupboard never opens with half-empty boxes.
    final wantDeep = layers > 1 && deepShare > 0 ? min(3, boxes) : 0;
    final front = min(frontCap, goods - trayFront - wantDeep);
    if (front < 2 * boxes) return null;
    final deep = goods - trayFront - front;
    // Depth each box and tray picked for itself. Deeper levels roll more often
    // and we keep rolling until the hidden goods actually have somewhere to
    // sit, so a designed deepShare never collapses into a flat board.
    final boxExtra = List<int>.filled(boxes, 0);
    final trayExtra = List<int>.filled(trays, 0);
    var boxDeepCap = 0;
    var trayDeepCap = 0;
    void ensureDepth() {
      boxDeepCap = 0;
      trayDeepCap = 0;
      for (var b = 0; b < boxes; b++) {
        boxDeepCap += boxExtra[b] * slotsPerShelf;
      }
      for (var t = 0; t < trays; t++) {
        trayDeepCap += trayExtra[t] * 2;
      }
    }

    // Seed with a random roll so stacks stay uneven box to box.
    for (var b = 0; b < boxes; b++) {
      boxExtra[b] = _rollDepth(rng, layers, deepShare);
    }
    for (var t = 0; t < trays; t++) {
      trayExtra[t] = _rollDepth(rng, trayLayers, deepShare);
    }
    ensureDepth();

    // Top up any box or tray that still has room until the deep goods fit.
    final bumpOrder = <({bool tray, int i})>[
      for (var b = 0; b < boxes; b++) (tray: false, i: b),
      for (var t = 0; t < trays; t++) (tray: true, i: t),
    ]..shuffle(rng);
    var guard = 0;
    while (boxDeepCap + trayDeepCap < deep && guard < 200) {
      guard += 1;
      var grew = false;
      for (final e in bumpOrder) {
        if (boxDeepCap + trayDeepCap >= deep) break;
        if (e.tray) {
          if (trayExtra[e.i] >= trayLayers - 1) continue;
          trayExtra[e.i] += 1;
          trayDeepCap += 2;
          grew = true;
        } else {
          if (boxExtra[e.i] >= layers - 1) continue;
          boxExtra[e.i] += 1;
          boxDeepCap += slotsPerShelf;
          grew = true;
        }
      }
      if (!grew) break;
      bumpOrder.shuffle(rng);
    }
    if (boxDeepCap + trayDeepCap < deep) return null;

    // Front row: every box is stocked full, then a few single places are taken
    // back out as working room. No box ever starts with just one good, and none
    // starts empty.
    final frontCount = List<int>.filled(boxes, slotsPerShelf);
    var gaps = boxes * slotsPerShelf - front;
    final gapOrder = [for (var b = 0; b < boxes; b++) b]..shuffle(rng);
    for (final b in gapOrder) {
      if (gaps <= 0) break;
      frontCount[b] -= 1;
      gaps -= 1;
    }
    if (gaps > 0) return null;

    // Hidden layers: spread the deep goods over the layers the boxes and trays
    // rolled for themselves, boxes first so the belt stays lighter.
    final deepCells = <({int shelfId, int depth, int cap})>[];
    for (var b = 0; b < boxes; b++) {
      for (var d = 1; d <= boxExtra[b]; d++) {
        deepCells.add((shelfId: b + 1, depth: d, cap: slotsPerShelf));
      }
    }
    final trayDeepStart = deepCells.length;
    for (var t = 0; t < trays; t++) {
      for (var d = 1; d <= trayExtra[t]; d++) {
        deepCells.add((shelfId: boxes + 1 + t, depth: d, cap: 2));
      }
    }

    final counts = List<int>.filled(deepCells.length, 0);
    final deepTickets = <int>[
      for (var i = 0; i < trayDeepStart; i++)
        for (var k = 0; k < deepCells[i].cap; k++) i,
    ]..shuffle(rng);
    final trayTickets = <int>[
      for (var i = trayDeepStart; i < deepCells.length; i++)
        for (var k = 0; k < deepCells[i].cap; k++) i,
    ]..shuffle(rng);
    // Around a fifth of the hidden goods ride in behind the tray fronts.
    final wantTrayDeep = min(trayTickets.length, (deep * 0.22).round());
    var placedDeep = 0;
    for (final i in trayTickets.take(wantTrayDeep)) {
      counts[i] += 1;
      placedDeep += 1;
    }
    // Every box that rolled a layer gets a good in it first, so depth is spread
    // across the cupboard instead of piling up in a handful of boxes.
    final seedOrder = [
      for (var i = 0; i < trayDeepStart; i++)
        if (deepCells[i].depth == 1) i,
    ]..shuffle(rng);
    for (final i in seedOrder) {
      if (placedDeep >= deep) break;
      counts[i] += 1;
      placedDeep += 1;
    }
    for (final i in deepTickets) {
      if (placedDeep >= deep) break;
      if (counts[i] >= deepCells[i].cap) continue;
      counts[i] += 1;
      placedDeep += 1;
    }
    for (final i in trayTickets) {
      if (placedDeep >= deep) break;
      if (counts[i] >= deepCells[i].cap) continue;
      counts[i] += 1;
      placedDeep += 1;
    }
    if (placedDeep < deep) return null;

    return [
      for (var b = 0; b < boxes; b++)
        (shelfId: b + 1, depth: 0, count: frontCount[b]),
      for (var t = 0; t < trays; t++)
        (shelfId: boxes + 1 + t, depth: 0, count: trayFrontCount[t]),
      for (var i = 0; i < deepCells.length; i++)
        if (counts[i] > 0)
          (
            shelfId: deepCells[i].shelfId,
            depth: deepCells[i].depth,
            count: counts[i],
          ),
    ];
  }

  /// How many layers a single box or tray hides behind its front row.
  static int _rollDepth(Random rng, int maxLayers, double deepShare) {
    if (maxLayers <= 1 || deepShare <= 0) return 0;
    var extra = 0;
    for (var d = 1; d < maxLayers; d++) {
      // The first hidden layer is likely so depth shows up all over the
      // cupboard; deeper ones taper off, so only a few boxes stack really high.
      final chance = d == 1
          ? (deepShare * 3.4).clamp(0.25, 0.95)
          : (deepShare * (2.4 - 0.3 * d)).clamp(0.15, 0.9);
      if (rng.nextDouble() > chance) break;
      extra += 1;
    }
    return extra;
  }

  /// Fills the planned cells with sets of three, keeping any cell from holding
  /// a finished set of its own.
  static List<InitialPlacement>? _assign({
    required Random rng,
    required int levelId,
    required List<({int shelfId, int depth, int count})> cells,
    required int sets,
    required String tint,
  }) {
    // Product families are handed out in shuffled order; once every family has
    // been used a level starts a second set of one, which reads as two very
    // similar goods to sort apart.
    final types = List<String>.from(productTypes)..shuffle(rng);

    // A set either stands two-together with its third elsewhere, or arrives as
    // three loose goods on the harder levels.
    final hardness = hardnessFor(levelId);
    final chunks = <List<String>>[];
    for (var s = 0; s < sets; s++) {
      final type = types[s % types.length];
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

    final stocked = List.generate(cells.length, (_) => <String>[]);

    bool fits(int index, List<String> chunk) {
      if (stocked[index].length + chunk.length > cells[index].count) {
        return false;
      }
      // Three of a kind together — in a box or on a tray — would already be
      // sold before the player touched it.
      final same = stocked[index].where((t) => t == chunk.first).length;
      return same + chunk.length < slotsPerShelf;
    }

    // Pairs are stocked first so they get the roomier cells; the order cells
    // are tried in is shuffled so the board never fills left to right.
    chunks.sort((a, b) => b.length.compareTo(a.length));
    final order = [for (var i = 0; i < cells.length; i++) i];
    for (final chunk in chunks) {
      order.shuffle(rng);
      var placed = false;
      for (final i in order) {
        if (!fits(i, chunk)) continue;
        stocked[i].addAll(chunk);
        placed = true;
        break;
      }
      if (!placed) return null;
    }

    // Every cell in the plan has to end up exactly as full as planned,
    // otherwise a box could start empty or a good would go missing.
    for (var i = 0; i < cells.length; i++) {
      if (stocked[i].length != cells[i].count) return null;
    }

    var counter = 0;
    final placements = <InitialPlacement>[];
    for (var i = 0; i < cells.length; i++) {
      final stock = stocked[i]..shuffle(rng);
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
}
