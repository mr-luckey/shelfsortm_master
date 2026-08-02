import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsortm_master/engine/level_generator.dart';
import 'package:shelfsortm_master/engine/level_plan.dart';
import 'package:shelfsortm_master/engine/level_validator.dart';
import 'package:shelfsortm_master/engine/match_engine.dart';
import 'package:shelfsortm_master/engine/mechanics/conveyor_tray.dart';
import 'package:shelfsortm_master/engine/mechanics/mechanic_ids.dart';

void main() {
  group('ConveyorTrayMechanic', () {
    test('wraps without teleporting while on screen', () {
      final m = ConveyorTrayMechanic()
        ..trayCount = 2
        ..viewportTrays = 3.2
        ..speed = 1.0
        ..direction = 1;
      expect(m.beltLength, greaterThan(m.viewportTrays));
      expect(m.spacing, greaterThan(1));

      final before = [m.positionOf(0), m.positionOf(1)];
      m.advance(0.05);
      final after = [m.positionOf(0), m.positionOf(1)];
      for (var i = 0; i < 2; i++) {
        // While a tray is still in the window its position only drifts forward.
        if (before[i] < m.viewportTrays && after[i] < m.viewportTrays) {
          expect(after[i], greaterThan(before[i]));
        }
      }
    });

    test('keeps tray identity across a full loop', () {
      final level = LevelGenerator.generate(11);
      final engine = MatchEngine(level: level);
      final m = engine.mechanics.ofType<ConveyorTrayMechanic>()!;
      final indices = m.trayShelfIndices;
      expect(indices.length, 2);

      final goods = [
        for (final i in indices)
          engine.shelves[i].slots.map((s) => s.front?.id).toList(),
      ];

      // Ride past a full belt length; the same goods stay on the same trays.
      for (var i = 0; i < 40; i++) {
        m.advance(0.1);
      }
      expect(m.offset, inInclusiveRange(0, m.beltLength));
      for (var t = 0; t < indices.length; t++) {
        final now = engine.shelves[indices[t]].slots
            .map((s) => s.front?.id)
            .toList();
        expect(now, goods[t]);
      }
    });

    test('slows while carrying and restores after', () {
      final m = ConveyorTrayMechanic()
        ..trayCount = 3
        ..speed = 1
        ..slowFactor = 0.5;
      expect(m.speedFactor, 1);
      m.setCarrying(true);
      for (var i = 0; i < 30; i++) {
        m.advance(0.05);
      }
      expect(m.speedFactor, closeTo(0.5, 0.01));
      m.setCarrying(false);
      for (var i = 0; i < 40; i++) {
        m.advance(0.05);
      }
      expect(m.speedFactor, closeTo(1.0, 0.01));
    });
  });

  group('tray levels', () {
    test('levels 1-10 have no trays', () {
      for (var i = 1; i <= 10; i++) {
        final level = LevelGenerator.generate(i);
        expect(level.trayCount, 0, reason: 'L$i');
        expect(level.mechanics, isNot(contains(MechanicIds.conveyorTray)));
      }
    });

    test('levels 11-20 introduce trays and stay fair', () {
      for (var i = 11; i <= 20; i++) {
        final plan = LevelPlan.forLevel(i);
        final level = LevelGenerator.generate(i);
        expect(level.trayCount, plan.trayCount, reason: 'L$i');
        expect(level.trayCount, inInclusiveRange(2, 8), reason: 'L$i');
        expect(level.mechanics, contains(MechanicIds.conveyorTray));
        expect(LevelValidator.problems(level), isEmpty, reason: 'L$i');

        final engine = MatchEngine(level: level);
        final m = engine.mechanics.ofType<ConveyorTrayMechanic>();
        expect(m, isNotNull, reason: 'L$i');
        expect(m!.trayShelfIndices.length, level.trayCount);
        expect(engine.isWon, isFalse, reason: 'L$i');

        final trayItems = level.initialPlacement
            .where((p) => p.shelfId > level.shelfCount)
            .length;
        expect(trayItems, greaterThan(0), reason: 'L$i');
      }
    });

    test('a tray good can move onto the cupboard', () {
      final level = LevelGenerator.generate(11);
      final engine = MatchEngine(level: level);
      final m = engine.mechanics.ofType<ConveyorTrayMechanic>()!;
      final trayIndex = m.trayShelfIndices.first;

      BoardPos? from;
      for (var s = 0; s < engine.shelves[trayIndex].slots.length; s++) {
        if (engine.shelves[trayIndex].slots[s].front != null) {
          from = BoardPos(trayIndex, s);
          break;
        }
      }
      expect(from, isNotNull);

      BoardPos? to;
      for (var i = 0; i < level.shelfCount; i++) {
        final empty = engine.shelves[i].firstEmptyIndex;
        if (empty >= 0) {
          to = BoardPos(i, empty);
          break;
        }
      }
      expect(to, isNotNull);
      expect(engine.move(from!, to!), isTrue);
    });
  });
}
