import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsortm_master/engine/level_generator.dart';
import 'package:shelfsortm_master/engine/match_engine.dart';
import 'package:shelfsortm_master/models/item.dart';
import 'package:shelfsortm_master/models/shelf.dart';

void main() {
  test('levels: 3-slot shelves, buffers, item count % 3 == 0', () {
    final sample = [
      for (var i = 1; i <= 250; i++)
        if (i <= 10 || i % 25 == 0 || i == 250) i,
    ];
    for (final i in sample) {
      final level = LevelGenerator.generate(i);
      expect(level.slotsPerShelf, 3);
      expect(level.bufferShelves, greaterThanOrEqualTo(2));
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
