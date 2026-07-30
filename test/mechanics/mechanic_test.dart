import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsortm_master/engine/level_generator.dart';
import 'package:shelfsortm_master/engine/match_engine.dart';
import 'package:shelfsortm_master/engine/mechanics/frozen_item.dart';
import 'package:shelfsortm_master/engine/mechanics/hidden_back_row.dart';
import 'package:shelfsortm_master/engine/mechanics/locked_item.dart';
import 'package:shelfsortm_master/engine/mechanics/mechanic_ids.dart';
import 'package:shelfsortm_master/engine/mechanics/mechanic_manager.dart';
import 'package:shelfsortm_master/engine/mechanics/moving_bottom_tray.dart';
import 'package:shelfsortm_master/engine/mechanics/sliding_shelf.dart';
import 'package:shelfsortm_master/models/item.dart';
import 'package:shelfsortm_master/models/level_data.dart';
import 'package:shelfsortm_master/models/shelf.dart';

void main() {
  group('mechanic progression', () {
    test('levels 1-10 have no dynamic mechanics', () {
      for (var i = 1; i <= 10; i++) {
        final level = LevelGenerator.generate(i);
        expect(level.mechanics, isEmpty, reason: 'Level $i');
      }
    });

    test('levels 11-15 introduce hidden_back_row', () {
      for (var i = 11; i <= 15; i++) {
        final level = LevelGenerator.generate(i);
        expect(level.mechanics, contains(MechanicIds.hiddenBackRow));
      }
    });

    test('level 25 boss combines 3 mechanics', () {
      final level = LevelGenerator.generate(25);
      expect(level.mechanics.length, greaterThanOrEqualTo(3));
      expect(level.mechanics, contains(MechanicIds.hiddenBackRow));
      expect(level.mechanics, contains(MechanicIds.movingBottomTray));
      expect(level.mechanics, contains(MechanicIds.lockedItems));
    });

    test('level 26 rest has no mechanics', () {
      expect(LevelGenerator.generate(26).mechanics, isEmpty);
    });

    test('level 51 rest has no mechanics', () {
      expect(LevelGenerator.generate(51).mechanics, isEmpty);
    });
  });

  group('MechanicManager', () {
    test('initializes from level JSON and save/load roundtrip', () {
      final level = LevelGenerator.generate(15);
      final engine = MatchEngine(level: level);
      expect(engine.mechanics.has(MechanicIds.hiddenBackRow), isTrue);
      expect(engine.mechanics.ofType<HiddenBackRowMechanic>(), isNotNull);

      final save = engine.toSaveJson();
      final engine2 = MatchEngine(level: level);
      engine2.loadSaveJson(save);
      expect(engine2.mechanics.has(MechanicIds.hiddenBackRow), isTrue);
    });

    test('moving tray ticks and saves position', () {
      final level = LevelData(
        levelId: 16,
        themeRoom: 'kitchen',
        difficulty: 'standard',
        timeLimit: 120,
        shelfCount: 5,
        slotsPerShelf: 3,
        bufferShelves: 2,
        initialPlacement: const [
          InitialPlacement(itemId: 'mug_red_001', shelfId: 1, slot: 0),
          InitialPlacement(itemId: 'mug_red_002', shelfId: 1, slot: 1),
          InitialPlacement(itemId: 'mug_red_003', shelfId: 2, slot: 0),
        ],
        starThresholds: const StarThresholds(threeStar: 20, twoStar: 30),
        mechanics: const [MechanicIds.movingBottomTray],
        mechanicConfig: const {
          'movingBottomTray': {
            'slotCount': 4,
            'speed': 1.0,
            'pauseAtEnds': 0.0,
          },
        },
      );
      final engine = MatchEngine(level: level);
      expect(engine.status, GameStatus.playing);
      final tray = engine.mechanics.ofType<MovingBottomTrayMechanic>()!;
      final before = tray.position;
      engine.tickMechanics(0.2);
      expect(tray.position, isNot(before));
      final state = tray.saveState();
      tray.position = 0;
      tray.loadState(state);
      expect(tray.position, greaterThan(0));
    });
  });

  group('LockedItemMechanic', () {
    test('blocks interaction until sequence unlock', () {
      final level = LevelData(
        levelId: 21,
        themeRoom: 'kitchen',
        difficulty: 'hard',
        timeLimit: 120,
        shelfCount: 3,
        slotsPerShelf: 3,
        initialPlacement: [
          const InitialPlacement(itemId: 'mug_red_001', shelfId: 1, slot: 0),
          const InitialPlacement(itemId: 'cup_red_002', shelfId: 1, slot: 1),
          const InitialPlacement(itemId: 'jar_red_003', shelfId: 2, slot: 0),
        ],
        starThresholds: const StarThresholds(threeStar: 10, twoStar: 20),
        mechanics: const [MechanicIds.lockedItems],
        mechanicConfig: const {
          'lockedItems': {
            'locks': [
              {
                'shelfIndex': 0,
                'slotIndex': 0,
                'condition': 'sequence',
                'sequenceNeeded': 2,
              },
            ],
          },
        },
      );
      final engine = MatchEngine(level: level);
      final locked = engine.mechanics.ofType<LockedItemMechanic>()!;
      expect(locked.canInteract(const BoardPos(0, 0)), isFalse);
      expect(engine.tap(const BoardPos(0, 0)), isFalse);

      // Make two successful moves to empty slots to unlock
      expect(engine.move(const BoardPos(0, 1), const BoardPos(2, 0)), isTrue);
      expect(engine.move(const BoardPos(1, 0), const BoardPos(2, 1)), isTrue);
      expect(locked.canInteract(const BoardPos(0, 0)), isTrue);
    });
  });

  group('SlidingShelfMechanic', () {
    test('inaccessible slots reject placement', () {
      final level = LevelData(
        levelId: 27,
        themeRoom: 'bakery',
        difficulty: 'standard',
        timeLimit: 120,
        shelfCount: 3,
        slotsPerShelf: 3,
        initialPlacement: [
          const InitialPlacement(itemId: 'mug_red_001', shelfId: 1, slot: 0),
        ],
        starThresholds: const StarThresholds(threeStar: 10, twoStar: 20),
        mechanics: const [MechanicIds.slidingShelves],
        mechanicConfig: const {
          'slidingShelves': {
            'shelfIndices': [1],
            'direction': 'left',
            'trigger': 'on_move',
          },
        },
      );
      final engine = MatchEngine(level: level);
      final slide = engine.mechanics.ofType<SlidingShelfMechanic>()!;
      // Force shifted state
      slide.slideState = 0;
      slide.toggle();
      expect(engine.shelves[1].slots[0].accessible, isFalse);
      expect(
        engine.move(const BoardPos(0, 0), const BoardPos(1, 0)),
        isFalse,
      );
    });
  });

  group('FrozenItemMechanic', () {
    test('frozen front cannot be selected', () {
      final level = LevelData(
        levelId: 55,
        themeRoom: 'library',
        difficulty: 'hard',
        timeLimit: 120,
        shelfCount: 3,
        slotsPerShelf: 3,
        initialPlacement: [
          const InitialPlacement(itemId: 'mug_blue_001', shelfId: 1, slot: 0),
          const InitialPlacement(itemId: 'cup_blue_002', shelfId: 1, slot: 1),
        ],
        starThresholds: const StarThresholds(threeStar: 10, twoStar: 20),
        mechanics: const [MechanicIds.frozenItems],
        mechanicConfig: const {
          'frozenItems': {
            'frozen': [
              {
                'shelfIndex': 0,
                'slotIndex': 0,
                'layers': 1,
                'unlock': 'sequence',
              },
            ],
          },
        },
      );
      final engine = MatchEngine(level: level);
      expect(engine.mechanics.ofType<FrozenItemMechanic>(), isNotNull);
      expect(engine.tap(const BoardPos(0, 0)), isFalse);
      expect(engine.shelves[0].slots[0].freezeLayers, greaterThan(0));
    });
  });

  group('combo + stars', () {
    test('starsForMoves uses optimal thresholds', () {
      final level = LevelData(
        levelId: 1,
        themeRoom: 'kitchen',
        difficulty: 'easy',
        timeLimit: 120,
        shelfCount: 3,
        slotsPerShelf: 3,
        initialPlacement: const [],
        optimalMoves: 20,
        starThresholds: const StarThresholds(
          threeStar: 20,
          twoStar: 24,
          oneStar: 999,
        ),
      );
      expect(level.starsForMoves(18), 3);
      expect(level.starsForMoves(22), 2);
      expect(level.starsForMoves(40), 1);
    });

    test('combo increments on consecutive clears', () {
      final level = LevelGenerator.generate(1);
      final engine = MatchEngine(level: level);
      // Manually set up two match shelves
      engine.shelves[0] = engine.shelves[0].copyWith(
        slots: [
          ShelfSlot(stack: [GameItem.fromId('mug_red_001')]),
          ShelfSlot(stack: [GameItem.fromId('mug_red_002')]),
          const ShelfSlot(),
        ],
      );
      engine.shelves[1] = engine.shelves[1].copyWith(
        slots: [
          ShelfSlot(stack: [GameItem.fromId('mug_red_003')]),
          const ShelfSlot(),
          const ShelfSlot(),
        ],
      );
      expect(engine.move(const BoardPos(1, 0), const BoardPos(0, 2)), isTrue);
      expect(engine.matches, greaterThanOrEqualTo(1));
      expect(engine.combo, greaterThanOrEqualTo(1));
    });
  });

  group('createMechanic factory', () {
    test('all 11 mechanic ids create instances', () {
      for (final id in MechanicIds.all) {
        expect(createMechanic(id), isNotNull, reason: id);
      }
    });
  });
}
