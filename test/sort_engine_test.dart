import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsortm_master/engine/level_generator.dart';
import 'package:shelfsortm_master/engine/match_engine.dart';
import 'package:shelfsortm_master/models/item.dart';
import 'package:shelfsortm_master/models/shelf.dart';

void main() {
  test('sort challenge levels: 3-slot shelves + buffer empties', () {
    for (var i = 1; i <= 50; i++) {
      final level = LevelGenerator.generate(i);
      expect(level.slotsPerShelf, 3);
      expect(level.bufferShelves, 2);
      expect(level.initialPlacement.length % 3, 0);
      final engine = MatchEngine(level: level);
      final emptyShelves =
          engine.shelves.where((s) => s.isEmpty).length;
      expect(emptyShelves, greaterThanOrEqualTo(2), reason: 'Level $i');
      expect(engine.isWon, isFalse);
    }
  });

  test('move to buffer and clear match of 3', () {
    final level = LevelGenerator.generate(1);
    final engine = MatchEngine(level: level);

    // Find empty buffer shelf
    final buffer = engine.shelves.indexWhere((s) => s.isEmpty);
    expect(buffer, greaterThanOrEqualTo(0));

    // Place 3 mugs onto buffer
    engine.shelves[buffer] = engine.shelves[buffer].copyWith(
      slots: [
        ShelfSlot(item: GameItem.fromId('mug_red_001')),
        ShelfSlot(item: GameItem.fromId('mug_red_002')),
        ShelfSlot(item: GameItem.fromId('mug_red_003')),
      ],
    );
    // Trigger resolve via a no-op move... call resolve by moving away and back
    // Actually place via move API: clear buffer first then move
    engine.shelves[buffer] = engine.shelves[buffer].copyWith(
      slots: List.generate(3, (_) => const ShelfSlot()),
    );

    // Put three mugs on a source shelf then move them one by one
    // Simpler: directly set and call private via move of last piece
    // Put 2 on buffer, move 3rd from another shelf
    // Find any mug on board
    engine.shelves[buffer] = engine.shelves[buffer].copyWith(
      slots: [
        ShelfSlot(item: GameItem.fromId('mug_red_001')),
        ShelfSlot(item: GameItem.fromId('mug_red_002')),
        const ShelfSlot(),
      ],
    );
    // Inject third mug on shelf 0 slot if empty else overwrite temp
    // Use move from a temp placement on shelf 0
    final srcShelf = buffer == 0 ? 1 : 0;
    engine.shelves[srcShelf] = engine.shelves[srcShelf].copyWith(
      slots: [
        ShelfSlot(item: GameItem.fromId('mug_red_003')),
        const ShelfSlot(),
        const ShelfSlot(),
      ],
    );

    final ok = engine.move(
      BoardPos(srcShelf, 0),
      BoardPos(buffer, 2),
    );
    expect(ok, isTrue);
    expect(engine.matches, greaterThanOrEqualTo(1));
    expect(engine.shelves[buffer].isEmpty, isTrue);
  });

  test('tap select then place', () {
    final level = LevelGenerator.generate(1);
    final engine = MatchEngine(level: level);
    // find item
    late BoardPos from;
    late BoardPos to;
    for (var si = 0; si < engine.shelves.length; si++) {
      for (var slot = 0; slot < 3; slot++) {
        if (engine.shelves[si].slots[slot].item != null) {
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
