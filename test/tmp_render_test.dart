import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsortm_master/engine/level_generator.dart';
import 'package:shelfsortm_master/models/item.dart';
import 'package:shelfsortm_master/models/shelf.dart';
import 'package:shelfsortm_master/ui/premium/premium_shelf_grid.dart';

void main() {
  testWidgets('render preview', (tester) async {
    final level = LevelGenerator.generate(3, boxes: 16);
    final board = level.buildSortedChallengeBoard();
    final shelves = <Shelf>[for (final s in board) s];

    final nextLayers = <List<GameItem?>?>[
      for (var i = 0; i < shelves.length; i++)
        i.isEven
            ? [
                GameItem(id: 'a_$i', type: 'pizza', color: 'red'),
                null,
                GameItem(id: 'b_$i', type: 'birthdaycake', color: 'red'),
              ]
            : null,
    ];

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF2A1B10),
          body: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 390,
              height: 300,
              child: PremiumShelfGrid(
                shelves: shelves,
                clearingShelf: -1,
                inputLocked: false,
                nextLayers: nextLayers,
                onMove: (_, __) {},
              ),
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('tool/preview.png').writeAsBytesSync(
      bytes!.buffer.asUint8List(),
    );
  });
}
