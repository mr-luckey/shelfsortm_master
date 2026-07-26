import 'dart:math';

import '../models/level_data.dart';
import '../models/theme_room.dart';

/// Sort Challenge levels:
/// - Each shelf has 3 slots
/// - typeCount item types × 3 goods each
/// - shelfCount = typeCount + bufferShelves (empty working shelves)
/// - Items start mixed on non-buffer shelves
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

  static LevelData generate(int levelId) {
    final theme = ThemeRoom.forLevel(levelId);
    final difficulty = LevelDifficultyX.forLevel(levelId);
    final rng = Random(levelId * 7919 + 17);
    final cfg = _configFor(levelId);

    final types = List<String>.from(theme.itemTypes);
    while (types.length < cfg.typeCount) {
      types.add(theme.itemTypes[types.length % theme.itemTypes.length]);
    }
    final usedTypes = types.take(cfg.typeCount).toList();

    final items = <String>[];
    var counter = 0;
    for (final type in usedTypes) {
      final color = tintColors[rng.nextInt(tintColors.length)];
      for (var k = 0; k < 3; k++) {
        counter += 1;
        items.add('${type}_${color}_${counter.toString().padLeft(3, '0')}');
      }
    }

    final shelfCount = cfg.typeCount + cfg.bufferShelves;
    const slots = 3;

    // Place items only on first (shelfCount - buffer) shelves, shuffled
    final filledShelfCount = cfg.typeCount;
    final positions = <({int shelfId, int slot})>[];
    for (var s = 0; s < filledShelfCount; s++) {
      for (var slot = 0; slot < slots; slot++) {
        positions.add((shelfId: s + 1, slot: slot));
      }
    }

    var placements = <InitialPlacement>[];
    for (var attempt = 0; attempt < 40; attempt++) {
      items.shuffle(rng);
      positions.shuffle(rng);
      placements = [
        for (var i = 0; i < items.length; i++)
          InitialPlacement(
            itemId: items[i],
            shelfId: positions[i].shelfId,
            slot: positions[i].slot,
          ),
      ];
      if (!_hasInstantMatch(placements, filledShelfCount, slots)) break;
    }

    final timeLimit = _timeFor(difficulty, items.length);
    return LevelData(
      levelId: levelId,
      themeRoom: theme.id,
      difficulty: difficulty.name,
      timeLimit: timeLimit,
      shelfCount: shelfCount,
      slotsPerShelf: slots,
      bufferShelves: cfg.bufferShelves,
      initialPlacement: placements,
      optimalMoves: items.length,
      starThresholds: StarThresholds(
        threeStar: (timeLimit * 0.45).round(),
        twoStar: (timeLimit * 0.2).round(),
      ),
    );
  }

  static bool _hasInstantMatch(
    List<InitialPlacement> placements,
    int shelfCount,
    int slots,
  ) {
    final board = List.generate(shelfCount, (_) => <String>[]);
    for (final p in placements) {
      if (p.shelfId < 1 || p.shelfId > shelfCount) continue;
      board[p.shelfId - 1].add(p.itemId.split('_').first);
    }
    for (final shelf in board) {
      if (shelf.length < 3) continue;
      final counts = <String, int>{};
      for (final t in shelf) {
        counts[t] = (counts[t] ?? 0) + 1;
        if (counts[t]! >= 3) return true;
      }
    }
    return false;
  }

  static int _timeFor(LevelDifficulty d, int itemCount) {
    final base = (itemCount * 4.5).round() + 50;
    switch (d) {
      case LevelDifficulty.easy:
      case LevelDifficulty.rest:
        return (base * 1.5).round().clamp(90, 280);
      case LevelDifficulty.hard:
        return (base * 1.05).round().clamp(75, 220);
      case LevelDifficulty.tricky:
        return base.clamp(70, 210);
      case LevelDifficulty.boss:
        return (base * 0.95).round().clamp(100, 300);
      case LevelDifficulty.standard:
        return (base * 1.2).round().clamp(85, 240);
    }
  }

  static _Cfg _configFor(int levelId) {
    if (levelId <= 3) {
      return const _Cfg(typeCount: 3, bufferShelves: 2);
    }
    if (levelId <= 8) {
      return const _Cfg(typeCount: 4, bufferShelves: 2);
    }
    if (levelId <= 15) {
      return const _Cfg(typeCount: 4, bufferShelves: 2);
    }
    if (levelId <= 25) {
      return const _Cfg(typeCount: 5, bufferShelves: 2);
    }
    if (levelId == 50) {
      return const _Cfg(typeCount: 6, bufferShelves: 2);
    }
    if (levelId <= 40) {
      return const _Cfg(typeCount: 5, bufferShelves: 2);
    }
    return const _Cfg(typeCount: 6, bufferShelves: 2);
  }
}

class _Cfg {
  final int typeCount;
  final int bufferShelves;

  const _Cfg({required this.typeCount, required this.bufferShelves});
}
