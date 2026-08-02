import 'level_shapes.dart';

/// Per-level design recipe consumed by `LevelGenerator`.
///
/// A plan says how big the cupboard is, how many goods start hidden behind the
/// front row, and how busy the belt is. The front row itself is not authored:
/// the generator fills every box (three goods, a few boxes with two, never one)
/// and then buries [hidden] goods in the layers behind. Every knob only ever
/// climbs across the campaign, which is what makes each level harder than the
/// one before it.
class LevelPlan {
  final String shapeId;

  /// Goods that start hidden behind the front row (0 = flat board). This is the
  /// main difficulty knob once the cupboard stops growing: the front row is
  /// always stocked full, so everything authored here is memory work.
  final int hidden;

  /// Deepest a single box may stack. Boxes pick their own depth up to this, so
  /// the board is never a uniform grid of equal stacks.
  final int layers;

  /// Trays riding the belt below the cupboard (0 = no belt, max 8).
  final int trayCount;

  /// Deepest a single tray may stack; trays also pick their own depth.
  final int trayLayers;

  /// Belt speed in tray widths per second.
  final double traySpeed;

  /// Seconds of clock per good on the board. Lower means more pressure.
  final double secPerGood;

  /// Overrides [secPerGood] for the hand-set tutorial clocks.
  final int? timeLimit;

  final List<String> mechanics;
  final Map<String, dynamic> mechanicConfig;

  const LevelPlan({
    required this.shapeId,
    this.hidden = 0,
    this.layers = 1,
    this.trayCount = 0,
    this.trayLayers = 1,
    this.traySpeed = 0.24,
    this.secPerGood = 3.0,
    this.timeLimit,
    this.mechanics = const [],
    this.mechanicConfig = const {},
  });

  List<List<int>> get layout => LevelShapes.byId(shapeId);

  int get boxes => LevelShapes.boxCount(layout);

  int get cols => LevelShapes.colCount(layout);

  int get rows => LevelShapes.rowCount(layout);

  /// The 30 level campaign. Treat this as the whole game.
  ///
  /// 1-3 teach picking, carrying and matching on a cupboard that is already
  /// fully stocked. 4 introduces depth: goods hide behind the front row, a
  /// different number behind every box. 6 brings the belt. The cabinet then
  /// grows nearly every level up to the 4x10 wall on 20. From there it is the
  /// deep vault: the cabinets get smaller again but stack far deeper, so more
  /// and more of the level is hidden while the belt runs faster and the clock
  /// gets shorter, right down to level 30 where a small cupboard hides almost
  /// everything. Neighbouring levels never share a shape.
  static const Map<int, LevelPlan> campaign = {
    1: LevelPlan(shapeId: 'trio', timeLimit: 90),
    2: LevelPlan(shapeId: 'grid2x2', timeLimit: 110),
    3: LevelPlan(shapeId: 'grid3x2', timeLimit: 150),
    4: LevelPlan(
      shapeId: 'grid4x2',
      hidden: 3,
      layers: 2,
      secPerGood: 5.4,
    ),
    5: LevelPlan(
      shapeId: 'grid3x3',
      hidden: 6,
      layers: 2,
      secPerGood: 5.2,
    ),
    6: LevelPlan(
      shapeId: 'grid4x3',
      hidden: 12,
      layers: 2,
      trayCount: 4,
      traySpeed: 0.16,
      secPerGood: 5.0,
    ),
    7: LevelPlan(
      shapeId: 'grid3x4',
      hidden: 15,
      layers: 2,
      trayCount: 4,
      traySpeed: 0.18,
      secPerGood: 4.8,
    ),
    8: LevelPlan(
      shapeId: 'grid3x5',
      hidden: 21,
      layers: 3,
      trayCount: 5,
      traySpeed: 0.19,
      secPerGood: 4.6,
    ),
    9: LevelPlan(
      shapeId: 'grid4x4',
      hidden: 24,
      layers: 3,
      trayCount: 5,
      traySpeed: 0.20,
      secPerGood: 4.45,
    ),
    10: LevelPlan(
      shapeId: 'grid3x6',
      hidden: 30,
      layers: 3,
      trayCount: 6,
      trayLayers: 2,
      traySpeed: 0.22,
      secPerGood: 4.3,
    ),
    11: LevelPlan(
      shapeId: 'podium4x5',
      hidden: 34,
      layers: 3,
      trayCount: 6,
      trayLayers: 2,
      traySpeed: 0.23,
      secPerGood: 4.15,
    ),
    12: LevelPlan(
      shapeId: 'grid4x5',
      hidden: 40,
      layers: 4,
      trayCount: 6,
      trayLayers: 2,
      traySpeed: 0.24,
      secPerGood: 4.0,
    ),
    13: LevelPlan(
      shapeId: 'grid3x7',
      hidden: 46,
      layers: 4,
      trayCount: 7,
      trayLayers: 2,
      traySpeed: 0.25,
      secPerGood: 3.85,
    ),
    14: LevelPlan(
      shapeId: 'grid4x6',
      hidden: 54,
      layers: 4,
      trayCount: 7,
      trayLayers: 2,
      traySpeed: 0.26,
      secPerGood: 3.7,
    ),
    15: LevelPlan(
      shapeId: 'grid3x8',
      hidden: 60,
      layers: 4,
      trayCount: 7,
      trayLayers: 3,
      traySpeed: 0.27,
      secPerGood: 3.55,
    ),
    16: LevelPlan(
      shapeId: 'grid3x9',
      hidden: 68,
      layers: 4,
      trayCount: 8,
      trayLayers: 3,
      traySpeed: 0.28,
      secPerGood: 3.4,
    ),
    17: LevelPlan(
      shapeId: 'grid4x7',
      hidden: 76,
      layers: 5,
      trayCount: 8,
      trayLayers: 3,
      traySpeed: 0.29,
      secPerGood: 3.3,
    ),
    18: LevelPlan(
      shapeId: 'grid3x10',
      hidden: 84,
      layers: 5,
      trayCount: 8,
      trayLayers: 3,
      traySpeed: 0.30,
      secPerGood: 3.2,
    ),
    19: LevelPlan(
      shapeId: 'grid4x8',
      hidden: 92,
      layers: 5,
      trayCount: 8,
      trayLayers: 3,
      traySpeed: 0.31,
      secPerGood: 3.1,
    ),
    20: LevelPlan(
      shapeId: 'grid4x10',
      hidden: 102,
      layers: 5,
      trayCount: 8,
      trayLayers: 3,
      traySpeed: 0.32,
      secPerGood: 3.0,
    ),
    21: LevelPlan(
      shapeId: 'grid4x9',
      hidden: 110,
      layers: 5,
      trayCount: 8,
      trayLayers: 4,
      traySpeed: 0.34,
      secPerGood: 2.9,
    ),
    22: LevelPlan(
      shapeId: 'grid4x8',
      hidden: 116,
      layers: 5,
      trayCount: 8,
      trayLayers: 4,
      traySpeed: 0.35,
      secPerGood: 2.8,
    ),
    23: LevelPlan(
      shapeId: 'grid3x10',
      hidden: 122,
      layers: 5,
      trayCount: 8,
      trayLayers: 4,
      traySpeed: 0.36,
      secPerGood: 2.7,
    ),
    24: LevelPlan(
      shapeId: 'grid4x7',
      hidden: 128,
      layers: 5,
      trayCount: 8,
      trayLayers: 4,
      traySpeed: 0.37,
      secPerGood: 2.6,
    ),
    25: LevelPlan(
      shapeId: 'grid3x9',
      hidden: 132,
      layers: 5,
      trayCount: 8,
      trayLayers: 4,
      traySpeed: 0.38,
      secPerGood: 2.5,
    ),
    26: LevelPlan(
      shapeId: 'grid3x8',
      hidden: 138,
      layers: 5,
      trayCount: 8,
      trayLayers: 4,
      traySpeed: 0.40,
      secPerGood: 2.4,
    ),
    27: LevelPlan(
      shapeId: 'grid3x7',
      hidden: 144,
      layers: 5,
      trayCount: 8,
      trayLayers: 4,
      traySpeed: 0.41,
      secPerGood: 2.3,
    ),
    28: LevelPlan(
      shapeId: 'grid4x5',
      hidden: 148,
      layers: 5,
      trayCount: 8,
      trayLayers: 4,
      traySpeed: 0.43,
      secPerGood: 2.2,
    ),
    29: LevelPlan(
      shapeId: 'grid3x6',
      hidden: 152,
      layers: 5,
      trayCount: 8,
      trayLayers: 4,
      traySpeed: 0.44,
      secPerGood: 2.1,
    ),
    30: LevelPlan(
      shapeId: 'grid4x4',
      hidden: 158,
      layers: 5,
      trayCount: 8,
      trayLayers: 4,
      traySpeed: 0.46,
      secPerGood: 2.0,
    ),
  };

  /// Last authored level. The campaign is 30 levels long; anything past it
  /// replays the closing levels so a stray level id still opens a board.
  static const int lastLevel = 30;

  static LevelPlan forLevel(int levelId) {
    final authored = campaign[levelId];
    if (authored != null) return authored;
    if (levelId < 1) return campaign[1]!;
    // Past the campaign, cycle the final ten levels.
    return campaign[21 + ((levelId - 31) % 10)]!;
  }
}
