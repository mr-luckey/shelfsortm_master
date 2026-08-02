import 'level_shapes.dart';

/// Per-level (or per-band) design recipe consumed by [LevelGenerator].
class LevelPlan {
  final String shapeId;
  final int typeCount;
  final int layers;
  final int? timeLimit;

  /// Trays riding the belt below the cupboard (0 = no belt, max 8).
  final int trayCount;

  /// Belt speed in trays per second.
  final double traySpeed;

  /// +1 rides right, -1 rides left.
  final int trayDirection;

  final List<String> mechanics;
  final Map<String, dynamic> mechanicConfig;

  const LevelPlan({
    required this.shapeId,
    required this.typeCount,
    required this.layers,
    this.timeLimit,
    this.trayCount = 0,
    this.traySpeed = 0.24,
    this.trayDirection = 1,
    this.mechanics = const [],
    this.mechanicConfig = const {},
  });

  List<List<int>> get layout => LevelShapes.byId(shapeId);

  int get boxes => LevelShapes.boxCount(layout);

  /// Explicit designs for the tutorial / early campaign.
  ///
  /// 1-3 teach the basics, 4-6 bring new cupboard shapes, 7-10 shrink the
  /// cupboard and stack hidden layers, 11-15 introduce the moving trays and
  /// 16-20 push the belt further.
  static const Map<int, LevelPlan> early = {
    1: LevelPlan(shapeId: 'pair', typeCount: 1, layers: 1, timeLimit: 180),
    2: LevelPlan(shapeId: 'trio', typeCount: 2, layers: 1, timeLimit: 170),
    3: LevelPlan(shapeId: 'grid3x2', typeCount: 4, layers: 1, timeLimit: 160),
    4: LevelPlan(shapeId: 'stair7', typeCount: 5, layers: 1, timeLimit: 155),
    5: LevelPlan(shapeId: 'lShape', typeCount: 4, layers: 1, timeLimit: 150),
    6: LevelPlan(shapeId: 'grid3x3', typeCount: 7, layers: 1, timeLimit: 150),
    7: LevelPlan(shapeId: 'offset', typeCount: 5, layers: 2, timeLimit: 145),
    8: LevelPlan(shapeId: 'grid2x2', typeCount: 6, layers: 2, timeLimit: 145),
    9: LevelPlan(shapeId: 'uShape', typeCount: 6, layers: 2, timeLimit: 140),
    10: LevelPlan(shapeId: 'tShape', typeCount: 7, layers: 2, timeLimit: 140),
    11: LevelPlan(
      shapeId: 'grid3x2',
      typeCount: 6,
      layers: 1,
      timeLimit: 150,
      trayCount: 2,
      traySpeed: 0.18,
    ),
    12: LevelPlan(
      shapeId: 'stair7',
      typeCount: 7,
      layers: 1,
      timeLimit: 150,
      trayCount: 2,
      traySpeed: 0.18,
      trayDirection: -1,
    ),
    13: LevelPlan(
      shapeId: 'lShape',
      typeCount: 6,
      layers: 1,
      timeLimit: 145,
      trayCount: 3,
      traySpeed: 0.22,
    ),
    14: LevelPlan(
      shapeId: 'grid3x3',
      typeCount: 9,
      layers: 1,
      timeLimit: 145,
      trayCount: 3,
      traySpeed: 0.22,
      trayDirection: -1,
    ),
    15: LevelPlan(
      shapeId: 'grid4x2',
      typeCount: 12,
      layers: 2,
      timeLimit: 145,
      trayCount: 4,
      traySpeed: 0.26,
    ),
    16: LevelPlan(
      shapeId: 'tallNarrow',
      typeCount: 13,
      layers: 2,
      timeLimit: 145,
      trayCount: 5,
      traySpeed: 0.26,
      trayDirection: -1,
    ),
    17: LevelPlan(
      shapeId: 'offset',
      typeCount: 8,
      layers: 3,
      timeLimit: 140,
      trayCount: 5,
      traySpeed: 0.30,
    ),
    18: LevelPlan(
      shapeId: 'pyramid',
      typeCount: 13,
      layers: 2,
      timeLimit: 140,
      trayCount: 6,
      traySpeed: 0.30,
      trayDirection: -1,
    ),
    19: LevelPlan(
      shapeId: 'uShape',
      typeCount: 11,
      layers: 3,
      timeLimit: 140,
      trayCount: 7,
      traySpeed: 0.34,
    ),
    20: LevelPlan(
      shapeId: 'medium12',
      typeCount: 18,
      layers: 2,
      timeLimit: 140,
      trayCount: 8,
      traySpeed: 0.34,
      trayDirection: -1,
    ),
  };

  /// Shape rotation used by the banded generator after the authored campaign.
  static const List<String> bandShapes = [
    'grid3x2',
    'stair7',
    'lShape',
    'tallNarrow',
    'offset',
    'uShape',
    'tShape',
    'grid4x2',
    'asymmetric8',
    'pyramid',
    'wide10',
    'medium12',
    'grid4x3',
    'grid3x3',
    'split',
    'grid4x4',
  ];

  /// First generated level; everything before this is authored above.
  static const int firstBandLevel = 21;

  static LevelPlan forLevel(int levelId) {
    final earlyPlan = early[levelId];
    if (earlyPlan != null) return earlyPlan;
    return _bandPlan(levelId);
  }

  static LevelPlan _bandPlan(int levelId) {
    // Cycle shapes so consecutive levels feel different.
    final shapeId = bandShapes[(levelId - 1) % bandShapes.length];
    final layout = LevelShapes.byId(shapeId);
    final boxes = LevelShapes.boxCount(layout);

    // Layers climb slowly, capped at 5.
    final layers = (1 + ((levelId - 1) ~/ 8)).clamp(1, 5);

    // The belt keeps growing and speeding up, up to eight trays.
    final step = ((levelId - firstBandLevel) ~/ 5).clamp(0, 8);
    final trayCount = (4 + step).clamp(2, 8);
    final traySpeed = (0.30 + 0.02 * step).clamp(0.18, 0.46);
    final trayDirection = levelId.isEven ? -1 : 1;

    // Leave room for carry space: roughly 1/4 of the front slots stay empty.
    final freeFrontTarget = boxes < 4 ? 2 : (boxes ~/ 4).clamp(2, boxes);
    final maxTypes =
        ((boxes * layers * 3 + trayCount * 2 - freeFrontTarget) ~/ 3)
            .clamp(1, 40);
    // Boards fill up as levels climb: about 60% stocked at first, packed later.
    final density = 0.6 + 0.4 * (((levelId - 16) / 60).clamp(0.0, 1.0));
    final typeCount = (maxTypes * density).floor().clamp(1, maxTypes);

    // Tighter clocks as levels climb; still above validator floor.
    final base = 90 + boxes * 4 + layers * 15 + trayCount * 3;
    final squeeze = ((levelId - firstBandLevel) * 0.4).round().clamp(0, 40);
    final timeLimit = (base - squeeze).clamp(75, 300);

    return LevelPlan(
      shapeId: shapeId,
      typeCount: typeCount,
      layers: layers,
      timeLimit: timeLimit,
      trayCount: trayCount,
      traySpeed: traySpeed.toDouble(),
      trayDirection: trayDirection,
    );
  }
}
