import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsortm_master/engine/level_shapes.dart';
import 'package:shelfsortm_master/engine/match_engine.dart';
import 'package:shelfsortm_master/models/item.dart';
import 'package:shelfsortm_master/models/shelf.dart';
import 'package:shelfsortm_master/ui/premium/board_drag.dart';
import 'package:shelfsortm_master/ui/premium/premium_shelf_grid.dart';
import 'package:shelfsortm_master/ui/premium/premium_wood_cell.dart';

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
  testWidgets('renders duo, 3x3, tall 4x10 and podium layouts',
      (tester) async {
    final cases = <String, List<List<int>>>{
      'duo': LevelShapes.byId('duo'),
      'grid3x3': LevelShapes.byId('grid3x3'),
      'grid4x10': LevelShapes.byId('grid4x10'),
      'podium4x5': LevelShapes.byId('podium4x5'),
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

  testWidgets('a good lands on the very place it was dropped on',
      (tester) async {
    final layout = LevelShapes.byId('duo');
    final shelves = [
      Shelf(
        shelfId: 1,
        slotCount: 3,
        slots: [
          ShelfSlot.front(GameItem.fromId('icecream_red_001')),
          const ShelfSlot(),
          const ShelfSlot(),
        ],
      ),
      Shelf(
        shelfId: 2,
        slotCount: 3,
        slots: const [ShelfSlot(), ShelfSlot(), ShelfSlot()],
      ),
    ];
    final drag = BoardDragController();
    addTearDown(drag.dispose);
    final moves = <({BoardPos from, BoardPos to})>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 640,
            child: PremiumShelfGrid(
              layout: layout,
              shelves: shelves,
              
              inputLocked: false,
              drag: drag,
              onMove: (from, to) => moves.add((from: from, to: to)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final board = tester.getRect(
      find.descendant(
        of: find.byType(PremiumShelfGrid),
        matching: find.byType(CustomPaint),
      ),
    );
    final colWidth = board.width / 2;

    Offset placeCenter(int col, int slot, {required bool sharedLeft}) {
      final cell = Rect.fromLTWH(0, 0, colWidth, board.height);
      final cavity = cavityMetrics(cell, edgeL: !sharedLeft, edgeR: sharedLeft);
      return Offset(
        board.left +
            col * colWidth +
            cavity.left +
            slotCenter(slot, cavity.width),
        board.top + cell.height * 0.6,
      );
    }

    final from = placeCenter(0, 0, sharedLeft: false);
    final onto = placeCenter(1, 2, sharedLeft: true);

    final gesture = await tester.startGesture(from);
    await tester.pump();
    await gesture.moveTo(onto);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(moves, hasLength(1));
    expect(moves.single.from, const BoardPos(0, 0));
    expect(moves.single.to, const BoardPos(1, 2));
  });

  test('a tall cupboard still spans the phone width', () {
    // Room left for the board on a 390 wide phone once the hud and belt are in.
    const available = Size(374, 548);
    for (final cols in [3, 4]) {
      final cell = PremiumShelfGrid.cellSizeFor(available, 10, cols);
      expect(
        cell.width * cols,
        closeTo(available.width, 0.01),
        reason: '$cols columns leave the cupboard narrow',
      );
      expect(cell.height * 10, lessThanOrEqualTo(available.height + 0.01));
      expect(cell.height, greaterThan(cell.width * 0.4));
    }
  });

  test('layout holes are not playable shelf ids', () {
    final layout = LevelShapes.byId('podium4x5');
    final ids = [
      for (final row in layout)
        for (final cell in row)
          if (cell > 0) cell,
    ];
    expect(ids.contains(0), isFalse);
    expect(layout.any((row) => row.contains(0)), isTrue);
    expect(LevelShapes.boxCount(layout), 18);
  });
}
