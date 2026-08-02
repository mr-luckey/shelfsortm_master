import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsortm_master/engine/level_shapes.dart';
import 'package:shelfsortm_master/models/item.dart';
import 'package:shelfsortm_master/models/shelf.dart';
import 'package:shelfsortm_master/ui/premium/premium_shelf_grid.dart';

List<Shelf> _shelvesFor(List<List<int>> layout) {
  final boxes = LevelShapes.boxCount(layout);
  return [
    for (var i = 1; i <= boxes; i++)
      Shelf(
        shelfId: i,
        slotCount: 3,
        slots: [
          ShelfSlot.front(GameItem.fromId('icecream_red_00$i')),
          const ShelfSlot(),
          const ShelfSlot(),
        ],
      ),
  ];
}

void main() {
  testWidgets('renders 2-box, 3x2 and L-shape layouts', (tester) async {
    final cases = <String, List<List<int>>>{
      'pair': LevelShapes.byId('pair'),
      'grid3x2': LevelShapes.byId('grid3x2'),
      'lShape': LevelShapes.byId('lShape'),
    };

    for (final e in cases.entries) {
      final layout = e.value;
      final shelves = _shelvesFor(layout);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: PremiumShelfGrid(
                layout: layout,
                shelves: shelves,
                clearingShelf: -1,
                inputLocked: false,
                onMove: (from, to) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PremiumShelfGrid), findsOneWidget, reason: e.key);
      expect(find.byType(CustomPaint), findsWidgets, reason: e.key);
    }
  });

  test('layout holes are not playable shelf ids', () {
    final layout = LevelShapes.byId('lShape');
    final ids = [
      for (final row in layout)
        for (final cell in row)
          if (cell > 0) cell,
    ];
    expect(ids.contains(0), isFalse);
    expect(layout.any((row) => row.contains(0)), isTrue);
    expect(LevelShapes.boxCount(layout), 5);
  });
}
