import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsortm_master/engine/match_engine.dart';
import 'package:shelfsortm_master/models/item.dart';
import 'package:shelfsortm_master/models/shelf.dart';
import 'package:shelfsortm_master/ui/premium/board_drag.dart';
import 'package:shelfsortm_master/ui/premium/premium_goods_fx.dart';

ShelfSlot _full(String id) => ShelfSlot.front(GameItem.fromId(id));

void main() {
  group('a dropped good keeps the place it was let go on', () {
    test('an empty box takes the good where it is dropped', () {
      final slots = [const ShelfSlot(), const ShelfSlot(), const ShelfSlot()];

      expect(dropSlot(slots, const BoardPos(2, 1)), const BoardPos(2, 1));
      expect(dropSlot(slots, const BoardPos(2, 2)), const BoardPos(2, 2));
      expect(dropSlot(slots, const BoardPos(2, 0)), const BoardPos(2, 0));
    });

    test('a taken place hands the good to the nearest free one', () {
      final slots = [
        const ShelfSlot(),
        _full('bottle_blue_001'),
        const ShelfSlot(),
      ];

      expect(dropSlot(slots, const BoardPos(0, 1)), const BoardPos(0, 0));
    });

    test('a full box refuses the good', () {
      final slots = [
        _full('bottle_blue_001'),
        _full('bottle_blue_002'),
        _full('bottle_blue_003'),
      ];

      expect(dropSlot(slots, const BoardPos(0, 1)), isNull);
    });
  });

  group('goods animations', () {
    test('a sale, a slide and a drop all run out and then stop', () {
      final fx = GoodsFx()
        ..startSell(3)
        ..slideForward('a')
        ..land('b');

      expect(fx.busy, isTrue);
      expect(fx.selling(3), isTrue);
      expect(fx.selling(4), isFalse);
      expect(fx.slideOf('a'), lessThan(1));
      expect(fx.landOf('b'), lessThan(1));

      for (var i = 0; i < 60; i++) {
        fx.advance(1 / 60);
      }

      expect(fx.busy, isFalse);
      expect(fx.sellOf(3), 1);
      expect(fx.slideOf('a'), 1);
      expect(fx.landOf('b'), 1);
    });

    test('a good never keeps a good in the air once it settles', () {
      // Mid-drop it is still above its place, at the end it stands on the shelf.
      expect(landPose(0.1, 40).rise, greaterThan(0));
      expect(landPose(1, 40).rise, 0);
      expect(landPose(1, 40).squash, 0);
    });

    test('a sold good swells, lifts away and fades out', () {
      final early = sellPose(0.2, 40);
      final late = sellPose(0.95, 40);

      expect(early.scale, greaterThan(1));
      expect(early.opacity, 1);
      expect(late.rise, greaterThan(early.rise));
      expect(late.opacity, lessThan(0.2));
    });
  });
}
