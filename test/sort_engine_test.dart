import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsortm_master/engine/level_generator.dart';
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

  test('layers grow one per level and cap out', () {
    expect(LevelGenerator.layersFor(1), 1);
    expect(LevelGenerator.layersFor(2), 2);
    expect(LevelGenerator.layersFor(3), 3);
    expect(LevelGenerator.layersFor(100), LevelGenerator.maxLayers);
    // Every flavor restarts the same curve.
    expect(LevelGenerator.layersFor(101), 1);
    expect(LevelGenerator.layersFor(102), 2);
    expect(LevelGenerator.layersFor(1001), 1);
  });

  test('the board keeps the same box count and 4 columns on every level', () {
    for (final id in [1, 2, 5, 20, 50, 100, 101, 500]) {
      final level = LevelGenerator.generate(id, boxes: 24);
      expect(level.shelfCount, 24);
      expect(level.layout.length, 6);
      expect(level.layout.every((row) => row.length == 4), isTrue);
    }
  });

  test('sorting hardness climbs from level 1 to 100 and restarts per flavor', () {
    expect(LevelGenerator.hardnessFor(1), 0);
    expect(LevelGenerator.hardnessFor(100), 1);
    expect(LevelGenerator.hardnessFor(101), 0);

    var previous = -1.0;
    for (var n = 1; n <= 100; n++) {
      final h = LevelGenerator.hardnessFor(n);
      expect(h, greaterThan(previous));
      previous = h;
    }
  });

  test('level 1 keeps matching sets together, level 100 scatters them', () {
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

    // Level 1: almost every box is already one move from a match.
    expect(readyBoxes(1), greaterThanOrEqualTo(2));
    // Level 100: sets are spread across boxes and layers.
    expect(readyBoxes(100), lessThan(15));
  });

  test('level 1 shows a single layer with one free spot per box', () {
    final level = LevelGenerator.generate(1);
    final engine = MatchEngine(level: level);
    expect(engine.waves.wavesRemaining, 0, reason: 'no layers behind');
    for (final shelf in engine.shelves) {
      expect(shelf.emptyFrontCount, greaterThanOrEqualTo(1));
      expect(shelf.slots.every((s) => s.stack.length <= 1), isTrue);
    }
  });

  test('a hidden layer only arrives once its box is emptied', () {
    final level = LevelGenerator.generate(2);
    final engine = MatchEngine(level: level);
    expect(engine.waves.nextWaveFor(engine.shelves.first.shelfId), isNotNull);

    // Carry every item out of box 0 into free spots elsewhere.
    var guard = 0;
    while (!engine.shelves[0].isEmpty && guard < 20) {
      guard++;
      final from = BoardPos(0, engine.shelves[0].slots.indexWhere((s) => !s.isEmpty));
      BoardPos? to;
      for (var si = 1; si < engine.shelves.length && to == null; si++) {
        final slot = engine.shelves[si].firstEmptyIndex;
        if (slot >= 0) to = BoardPos(si, slot);
      }
      if (to == null) break;
      engine.move(from, to);
    }
    // Emptying the box pulls its next layer forward automatically.
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
}
