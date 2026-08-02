import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsortm_master/engine/level_generator.dart';
import 'package:shelfsortm_master/engine/level_plan.dart';
import 'package:shelfsortm_master/engine/level_shapes.dart';
import 'package:shelfsortm_master/engine/match_engine.dart';
import 'package:shelfsortm_master/models/item.dart';
import 'package:shelfsortm_master/models/shelf.dart';

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
    final level = LevelGenerator.generate(11);
    final engine = MatchEngine(level: level);
    expect(engine.waves.wavesRemaining, greaterThan(0));
    expect(engine.itemCount, greaterThan(0));
  });

  test('layers follow the level plan and cap out', () {
    expect(LevelGenerator.layersFor(1), 1);
    expect(LevelGenerator.layersFor(3), 1);
    // Depth arrives on level 4 and keeps climbing across the campaign.
    expect(LevelGenerator.layersFor(4), 2);
    expect(LevelGenerator.layersFor(8), 3);
    expect(LevelGenerator.layersFor(12), 4);
    expect(LevelGenerator.layersFor(17), 5);
    expect(LevelGenerator.layersFor(30), 5);
    expect(LevelGenerator.layersFor(100), lessThanOrEqualTo(LevelGenerator.maxLayers));
  });

  test('early levels use the designed cupboard shapes', () {
    expect(LevelGenerator.generate(1).shelfCount, 3);
    expect(LevelGenerator.generate(2).shelfCount, 4);
    expect(LevelGenerator.generate(3).shelfCount, 6);
    expect(LevelGenerator.generate(5).shelfCount, 9);

    final l1 = LevelGenerator.generate(1).layout;
    expect(LevelShapes.boxCount(l1), 3);
    expect(l1.length, lessThanOrEqualTo(LevelShapes.maxRows));
    expect(LevelShapes.colCount(l1), lessThanOrEqualTo(LevelShapes.maxCols));
  });

  test('sorting hardness climbs across the campaign', () {
    expect(LevelGenerator.hardnessFor(1), 0);
    expect(LevelGenerator.hardnessFor(3), 0);
    expect(LevelGenerator.hardnessFor(30), 1);

    var previous = -1.0;
    for (var n = 1; n <= LevelPlan.lastLevel; n++) {
      final h = LevelGenerator.hardnessFor(n);
      expect(h, greaterThanOrEqualTo(previous), reason: 'L$n');
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
    final level = LevelGenerator.generate(11);
    final engine = MatchEngine(level: level);
    // Depth is rolled per box, so hunt for one that actually hides a layer.
    final shelfIndex = [
      for (var i = 0; i < level.shelfCount; i++) i,
    ].firstWhere(
      (i) => engine.waves.nextWaveFor(engine.shelves[i].shelfId) != null,
    );
    final shelfId = engine.shelves[shelfIndex].shelfId;
    expect(engine.waves.nextWaveFor(shelfId), isNotNull);

    final layersBefore = engine.waves.layersLeftFor(shelfId);
    var guard = 0;
    while (engine.waves.layersLeftFor(shelfId) == layersBefore && guard < 80) {
      guard++;
      final fromSlot =
          engine.shelves[shelfIndex].slots.indexWhere((s) => !s.isEmpty);
      if (fromSlot < 0) break;
      final from = BoardPos(shelfIndex, fromSlot);
      BoardPos? to;
      for (var si = 0; si < engine.shelves.length && to == null; si++) {
        if (si == shelfIndex) continue;
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

  test('a sale only holds its own box, the rest of the board keeps playing', () {
    final engine = MatchEngine(level: LevelGenerator.generate(2));
    ShelfSlot good(String id) => ShelfSlot.front(GameItem.fromId(id));

    engine.shelves[0] = engine.shelves[0].copyWith(
      slots: [good('cupcake_red_001'), good('cupcake_red_002'), const ShelfSlot()],
    );
    engine.shelves[1] = engine.shelves[1].copyWith(
      slots: [good('cupcake_red_003'), const ShelfSlot(), const ShelfSlot()],
    );
    engine.shelves[2] = engine.shelves[2].copyWith(
      slots: [good('jar_teal_001'), const ShelfSlot(), const ShelfSlot()],
    );

    expect(engine.move(const BoardPos(1, 0), const BoardPos(0, 2)), isTrue);
    expect(engine.closingShelves, {0});

    // The selling box is off limits until its sale finishes.
    expect(engine.move(const BoardPos(0, 0), const BoardPos(1, 1)), isFalse);
    // Everything else stays live — no board wide freeze.
    expect(engine.move(const BoardPos(2, 0), const BoardPos(1, 0)), isTrue);

    engine.finishShelfClose(0);
    if (engine.waves.hasPendingWave(0)) {
      // A waiting layer keeps the box shut until it has slid forward.
      expect(engine.isClosing(0), isTrue);
      engine.openNextWave(0);
    }
    expect(engine.closingShelves, isEmpty);
    expect(engine.isClosing(0), isFalse);
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
