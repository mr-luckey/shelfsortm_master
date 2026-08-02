import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsortm_master/engine/level_generator.dart';
import 'package:shelfsortm_master/engine/level_plan.dart';
import 'package:shelfsortm_master/engine/level_shapes.dart';
import 'package:shelfsortm_master/engine/match_engine.dart';

void main() {
  test('levels: 3-slot shelves, buffers, item count % 3 == 0', () {
    final sample = [
      for (var i = 1; i <= 1100; i++)
        if (i <= 10 || i % 100 == 0 || i == 1100) i,
    ];
    for (final i in sample) {
      final level = LevelGenerator.generate(i);
      expect(level.slotsPerShelf, 3);
      expect(level.bufferShelves, greaterThanOrEqualTo(1));
      expect(level.initialPlacement.length % 3, 0, reason: 'Level $i');
      final engine = MatchEngine(level: level);
      final emptyFronts = engine.emptyFrontCount;
      expect(emptyFronts, greaterThanOrEqualTo(2), reason: 'Level $i empties');
      expect(engine.isWon, isFalse);
    }
  });

  test('depth items queue as next shelf waves', () {
    final level = LevelGenerator.generate(15);
    final engine = MatchEngine(level: level);
    expect(engine.waves.wavesRemaining, greaterThan(0));
    expect(engine.itemCount, greaterThan(0));
  });

  test('layers follow the level plan and cap out', () {
    expect(LevelGenerator.layersFor(1), 1);
    expect(LevelGenerator.layersFor(2), 1);
    expect(LevelGenerator.layersFor(7), 2);
    expect(LevelGenerator.layersFor(15), 2);
    expect(LevelGenerator.layersFor(100), lessThanOrEqualTo(LevelGenerator.maxLayers));
  });

  test('early levels use the designed cupboard shapes', () {
    expect(LevelGenerator.generate(1).shelfCount, 2);
    expect(LevelGenerator.generate(2).shelfCount, 3);
    expect(LevelGenerator.generate(3).shelfCount, 6);
    expect(LevelGenerator.generate(4).shelfCount, 7);

    final l1 = LevelGenerator.generate(1).layout;
    expect(LevelShapes.boxCount(l1), 2);
    expect(l1.length, lessThanOrEqualTo(LevelShapes.maxRows));
    expect(LevelShapes.colCount(l1), lessThanOrEqualTo(LevelShapes.maxCols));
  });

  test('sorting hardness climbs across a flavor and restarts', () {
    expect(LevelGenerator.hardnessFor(1), 0);
    expect(LevelGenerator.hardnessFor(100), 1);
    expect(LevelGenerator.hardnessFor(101), 0);

    var previous = -1.0;
    for (var n = 16; n <= 100; n++) {
      final h = LevelGenerator.hardnessFor(n);
      expect(h, greaterThanOrEqualTo(previous));
      previous = h;
    }
  });

  test('level 1 keeps matching sets together, later levels scatter more', () {
    int readyBoxes(int levelId) {
      final fronts = <int, List<String>>{};
      for (final p in LevelGenerator.generate(levelId).initialPlacement) {
        if (p.depth != 0) continue;
        fronts.putIfAbsent(p.shelfId, () => []).add(p.itemId.split('_').first);
      }
      return fronts.values
          .where((t) => t.length >= 2 && t.toSet().length == 1)
          .length;
    }

    expect(readyBoxes(1), greaterThanOrEqualTo(1));
    expect(readyBoxes(100), lessThan(readyBoxes(1) + 20));
  });

  test('level 1 shows a single layer with room to carry goods', () {
    final level = LevelGenerator.generate(1);
    final engine = MatchEngine(level: level);
    expect(engine.waves.wavesRemaining, 0, reason: 'no layers behind');
    expect(engine.emptyFrontCount, greaterThanOrEqualTo(2));
    for (final shelf in engine.shelves) {
      expect(shelf.slots.every((s) => s.stack.length <= 1), isTrue);
    }
  });

  test('a hidden layer only arrives once its box is emptied', () {
    final level = LevelGenerator.generate(7);
    final engine = MatchEngine(level: level);
    expect(engine.waves.nextWaveFor(engine.shelves.first.shelfId), isNotNull);

    final shelfId = engine.shelves.first.shelfId;
    final layersBefore = engine.waves.layersLeftFor(shelfId);
    var guard = 0;
    while (engine.waves.layersLeftFor(shelfId) == layersBefore && guard < 40) {
      guard++;
      final fromSlot =
          engine.shelves[0].slots.indexWhere((s) => !s.isEmpty);
      if (fromSlot < 0) break;
      final from = BoardPos(0, fromSlot);
      BoardPos? to;
      for (var si = 1; si < engine.shelves.length && to == null; si++) {
        final slot = engine.shelves[si].firstEmptyIndex;
        if (slot >= 0) to = BoardPos(si, slot);
      }
      if (to == null) break;
      engine.move(from, to);
    }
    expect(engine.shelves[0].isEmpty, isFalse);
  });

  test('only empty columns accept moves', () {
    final level = LevelGenerator.generate(1);
    final engine = MatchEngine(level: level);
    BoardPos? from;
    BoardPos? occupied;
    for (var si = 0; si < engine.shelves.length; si++) {
      for (var slot = 0; slot < 3; slot++) {
        if (engine.shelves[si].slots[slot].front != null) {
          from ??= BoardPos(si, slot);
          if (from != BoardPos(si, slot)) {
            occupied = BoardPos(si, slot);
          }
        }
      }
    }
    expect(from, isNotNull);
    expect(occupied, isNotNull);
    expect(engine.move(from!, occupied!), isFalse);
  });

  test('tap select then place on empty', () {
    final level = LevelGenerator.generate(1);
    final engine = MatchEngine(level: level);
    late BoardPos from;
    late BoardPos to;
    for (var si = 0; si < engine.shelves.length; si++) {
      for (var slot = 0; slot < 3; slot++) {
        if (engine.shelves[si].slots[slot].front != null) {
          from = BoardPos(si, slot);
        }
        if (engine.shelves[si].slots[slot].isEmpty) {
          to = BoardPos(si, slot);
        }
      }
    }
    expect(engine.tap(from), isTrue);
    expect(engine.selected, from);
    expect(engine.tap(to), isTrue);
    expect(engine.selected, isNull);
  });

  test('level plans stay within the hard board limit', () {
    for (var id = 1; id <= 40; id++) {
      final plan = LevelPlan.forLevel(id);
      final layout = plan.layout;
      LevelShapes.validate(layout);
      expect(layout.length, lessThanOrEqualTo(LevelShapes.maxRows));
      expect(LevelShapes.colCount(layout), lessThanOrEqualTo(LevelShapes.maxCols));
    }
  });
}
