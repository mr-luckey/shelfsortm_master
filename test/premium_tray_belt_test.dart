import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsortm_master/engine/mechanics/conveyor_tray.dart';
import 'package:shelfsortm_master/models/item.dart';
import 'package:shelfsortm_master/models/shelf.dart';
import 'package:shelfsortm_master/ui/premium/board_drag.dart';
import 'package:shelfsortm_master/ui/premium/premium_tray_belt.dart';
import 'package:shelfsortm_master/ui/premium/premium_tray_plank.dart';

List<Shelf> _trays(int count) => [
      for (var i = 1; i <= count; i++)
        Shelf(
          shelfId: i,
          slotCount: 3,
          isDock: true,
          slots: [
            ShelfSlot.front(GameItem.fromId('icecream_red_00$i')),
            ShelfSlot.front(GameItem.fromId('bottle_blue_00$i')),
            const ShelfSlot(),
          ],
        ),
    ];

void main() {
  test('a plank is a thin board with headroom for goods on top', () {
    const rect = Rect.fromLTWH(0, 0, 120, 96);
    final surface = trayPlankSurface(rect);

    // The board sits low: nearly all of the cell is space above it.
    expect(surface.surfaceY, greaterThan(rect.height * 0.8));
    expect(surface.surfaceY, lessThan(rect.bottom));
    expect(surface.left, greaterThan(rect.left));
    expect(surface.width, lessThan(rect.width));
    expect(surface.width, greaterThan(rect.width * 0.7));
  });

  testWidgets('belt paints its trays and keeps rolling', (tester) async {
    final shelves = _trays(4);
    final mechanic = ConveyorTrayMechanic()
      ..trayCount = 4
      ..speed = 0.4;
    final drag = BoardDragController();
    addTearDown(drag.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: PremiumTrayBelt.height,
            child: PremiumTrayBelt(
              shelves: shelves,
              trayIndices: const [0, 1, 2, 3],
              mechanic: mechanic,
              inputLocked: false,
              drag: drag,
              onMove: (from, to) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PremiumTrayBelt), findsOneWidget);
    final before = mechanic.offset;
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 32));
    }
    expect(mechanic.offset, greaterThan(before));
  });
}
