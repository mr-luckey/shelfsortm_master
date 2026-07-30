import 'dart:math';

import '../models/level_data.dart';
import '../models/theme_room.dart';

/// Sort Challenge generator (Falcon-accurate):
/// - Mono color tint per level
/// - Depth stacks behind front goods
/// - Scattered empty buffer shelves
/// - Irregular cabinet layout rows
class LevelGenerator {
  static const tintColors = [
    'red',
    'blue',
    'green',
    'yellow',
    'purple',
    'orange',
    'pink',
    'teal',
  ];

  static LevelData generate(int levelId) {
    final theme = ThemeRoom.forLevel(levelId);
    final difficulty = LevelDifficultyX.forLevel(levelId);
    final rng = Random(levelId * 7919 + 17);
    final cfg = _configFor(levelId);
    final tint = tintColors[(levelId - 1) % tintColors.length];

    final types = List<String>.from(theme.itemTypes);
    while (types.length < cfg.typeCount) {
      types.add(theme.itemTypes[types.length % theme.itemTypes.length]);
    }
    final usedTypes = types.take(cfg.typeCount).toList();

    // Each type appears (3 * setsPerType) times so match-3 works at all depths
    final items = <String>[];
    var counter = 0;
    for (final type in usedTypes) {
      for (var k = 0; k < 3 * cfg.setsPerType; k++) {
        counter += 1;
        items.add('${type}_${tint}_${counter.toString().padLeft(3, '0')}');
      }
    }

    final shelfCount = cfg.filledShelves + cfg.bufferShelves;
    const slots = 3;

    final allIds = List<int>.generate(shelfCount, (i) => i + 1);
    allIds.shuffle(rng);
    final bufferIds = allIds.take(cfg.bufferShelves).toSet();
    final filledIds = allIds.where((id) => !bufferIds.contains(id)).toList();

    // Columns available for stacking (filled shelves × 3)
    final columns = <({int shelfId, int slot})>[];
    for (final id in filledIds) {
      for (var slot = 0; slot < slots; slot++) {
        columns.add((shelfId: id, slot: slot));
      }
    }

    // Distribute items into column stacks with depth 1..maxDepth
    var placements = <InitialPlacement>[];
    for (var attempt = 0; attempt < 50; attempt++) {
      items.shuffle(rng);
      columns.shuffle(rng);
      placements = _stackItems(items, columns, cfg.maxDepth, rng);
      if (!_hasInstantFrontMatch(placements, shelfCount, slots) &&
          placements.length == items.length) {
        break;
      }
    }

    final layout = LevelData.defaultLayout(shelfCount);
    final timeLimit = _timeFor(difficulty, items.length, cfg.maxDepth);
    final mech = _mechanicsFor(levelId, rng, shelfCount, filledIds, tint, items);

    // Move-based star thresholds (PRD §7.2)
    final optimal = items.length;
    final threeStar = optimal;
    final twoStar = (optimal * 1.2).ceil();

    return LevelData(
      levelId: levelId,
      themeRoom: theme.id,
      difficulty: difficulty.name,
      timeLimit: timeLimit,
      shelfCount: shelfCount,
      slotsPerShelf: slots,
      bufferShelves: cfg.bufferShelves,
      initialPlacement: placements,
      optimalMoves: optimal,
      levelTint: tint,
      layout: layout,
      mechanics: mech.ids,
      mechanicConfig: mech.config,
      seed: levelId * 7919 + 17,
      starThresholds: StarThresholds(
        threeStar: threeStar,
        twoStar: twoStar,
        oneStar: 999,
      ),
    );
  }

  /// PRD §6A.3 mechanic progression schedule.
  static ({List<String> ids, Map<String, dynamic> config}) _mechanicsFor(
    int levelId,
    Random rng,
    int shelfCount,
    List<int> filledIds,
    String tint,
    List<String> items,
  ) {
    final ids = <String>[];
    final config = <String, dynamic>{};

    void addHidden({int rows = 1}) {
      if (ids.contains('hidden_back_row')) return;
      ids.add('hidden_back_row');
      config['hiddenBackRow'] = {'rows': rows, 'revealMode': 'front_clear'};
    }

    void addTray() {
      if (ids.contains('moving_bottom_tray')) return;
      ids.add('moving_bottom_tray');
      config['movingBottomTray'] = {
        'slotCount': 4,
        'movementMode': 'ping_pong',
        'speed': 0.55 + (levelId % 5) * 0.05,
        'pauseAtEnds': 0.4,
      };
    }

    void addLocked() {
      if (ids.contains('locked_items')) return;
      ids.add('locked_items');
      final shelfId = filledIds.isNotEmpty ? filledIds.first : 1;
      config['lockedItems'] = {
        'locks': [
          {
            'slot': '$shelfId:0',
            'condition': 'sequence',
            'sequenceNeeded': 3,
          },
        ],
      };
    }

    void addSliding() {
      if (ids.contains('sliding_shelves')) return;
      ids.add('sliding_shelves');
      config['slidingShelves'] = {
        'shelfIndices': [0],
        'direction': levelId.isEven ? 'left' : 'right',
        'trigger': 'on_move',
        'speed': 0.5,
      };
    }

    void addMystery() {
      if (ids.contains('mystery_boxes')) return;
      ids.add('mystery_boxes');
      final shelfId = filledIds.length > 1
          ? filledIds[1]
          : (filledIds.isNotEmpty ? filledIds.first : 1);
      final hidden =
          items.isNotEmpty ? items[rng.nextInt(items.length)] : 'mug_${tint}_001';
      config['mysteryBoxes'] = {
        'boxes': [
          {
            'slot': '$shelfId:1',
            'itemId': hidden,
            'trigger': 'shelf_complete',
          },
        ],
      };
    }

    void addStacked() {
      if (ids.contains('stacked_items')) return;
      ids.add('stacked_items');
      config['stackedItems'] = {'maxDepth': 3};
    }

    void addConveyor() {
      if (ids.contains('conveyor_shelf')) return;
      ids.add('conveyor_shelf');
      config['conveyorShelf'] = {
        'speed': 0.3 + (levelId % 4) * 0.05,
        'visibleSlots': 4,
        'queue': <String>[],
      };
    }

    void addRotating() {
      if (ids.contains('rotating_tray')) return;
      ids.add('rotating_tray');
      config['rotatingTray'] = {
        'slotCount': 4,
        'speed': 0.4,
        'rotateMode': 'on_move',
        'clockwise': levelId.isOdd,
      };
    }

    void addFrozen() {
      if (ids.contains('frozen_items')) return;
      ids.add('frozen_items');
      final shelfId = filledIds.isNotEmpty ? filledIds.first : 1;
      config['frozenItems'] = {
        'frozen': [
          {
            'slot': '$shelfId:2',
            'layers': 1,
            'unlock': 'sequence',
          },
        ],
      };
    }

    void addDivider() {
      if (ids.contains('moving_divider')) return;
      ids.add('moving_divider');
      config['movingDivider'] = {
        'shelfIndex': 0,
        'dividerIndex': 1,
        'trigger': 'on_move',
        'positions': [1, 2],
      };
    }

    void addChain() {
      if (ids.contains('chain_release')) return;
      ids.add('chain_release');
      config['chainRelease'] = {
        'events': [
          {
            'trigger': 'type_clear',
            'steps': [
              {'action': 'reveal_hidden'},
            ],
          },
        ],
      };
    }

    // Progression schedule (PRD §6A.3)
    // Zone rest levels (26, 51, 76, …) — no dynamic mechanics
    if (levelId > 25 && (levelId - 1) % 25 == 0) {
      return (ids: ids, config: config);
    }

    if (levelId <= 5) {
      // Pure sorting — no mechanics
    } else if (levelId <= 10) {
      // Visual complexity / combos only — no dynamic mechanics yet
    } else if (levelId <= 15) {
      addHidden();
    } else if (levelId <= 20) {
      addHidden();
      addTray();
    } else if (levelId <= 24) {
      addHidden();
      addLocked();
    } else if (levelId == 25) {
      // Boss: Kitchen Master
      addHidden(rows: 2);
      addTray();
      addLocked();
    } else if (levelId == 26) {
      // Rest — no new mechanic
    } else if (levelId <= 35) {
      addHidden();
      if (levelId <= 29) {
        addSliding();
      } else if (levelId <= 32) {
        addMystery();
      } else {
        addStacked();
        addSliding();
      }
    } else if (levelId <= 40) {
      addHidden();
      if (levelId.isEven) {
        addConveyor();
      } else {
        addRotating();
      }
    } else if (levelId <= 49) {
      addHidden();
      addStacked();
      if (levelId % 3 == 0) {
        addLocked();
      } else if (levelId % 3 == 1) {
        addSliding();
        addMystery();
      } else {
        addTray();
        addRotating();
      }
    } else if (levelId == 50) {
      // Boss: Bakery Rush
      addHidden();
      addConveyor();
      addRotating();
      addMystery();
    } else if (levelId <= 75) {
      addHidden();
      addStacked();
      if (levelId <= 60) {
        addFrozen();
      } else if (levelId <= 70) {
        addDivider();
        addLocked();
      } else {
        addChain();
        addFrozen();
      }
      if (levelId == 75) {
        // Boss: Library Lockdown
        addLocked();
        addFrozen();
        addChain();
      }
    } else if (levelId <= 100) {
      addHidden();
      addStacked();
      final pick = levelId % 5;
      if (pick == 0) {
        addConveyor();
        addTray();
      } else if (pick == 1) {
        addRotating();
        addMystery();
      } else if (pick == 2) {
        addSliding();
        addDivider();
      } else if (pick == 3) {
        addFrozen();
        addLocked();
      } else {
        addChain();
        addMystery();
      }
      if (levelId == 100) {
        addTray();
        addConveyor();
        addChain();
      }
    } else {
      // 101+: combinations of learned mechanics
      addHidden();
      addStacked();
      final pool = [
        addTray,
        addSliding,
        addRotating,
        addConveyor,
        addLocked,
        addMystery,
        addFrozen,
        addDivider,
        addChain,
      ];
      final a = pool[levelId % pool.length];
      final b = pool[(levelId ~/ 3) % pool.length];
      a();
      if (a != b) b();
      if (levelId % 25 == 0) {
        // Boss every 25
        final c = pool[(levelId ~/ 7) % pool.length];
        if (c != a && c != b) c();
      }
    }

    return (ids: ids, config: config);
  }

  static List<InitialPlacement> _stackItems(
    List<String> items,
    List<({int shelfId, int slot})> columns,
    int maxDepth,
    Random rng,
  ) {
    // Assign each column a depth so sum(depths) == items.length
    final depths = List<int>.filled(columns.length, 1);
    var remaining = items.length - columns.length;
    if (remaining < 0) {
      // Fewer items than columns: leave some columns empty
      final used = columns.take(items.length).toList();
      return [
        for (var i = 0; i < items.length; i++)
          InitialPlacement(
            itemId: items[i],
            shelfId: used[i].shelfId,
            slot: used[i].slot,
            depth: 0,
          ),
      ];
    }
    var guard = 0;
    while (remaining > 0 && guard < 10000) {
      guard++;
      final i = rng.nextInt(columns.length);
      if (depths[i] < maxDepth) {
        depths[i]++;
        remaining--;
      }
    }

    final placements = <InitialPlacement>[];
    var idx = 0;
    for (var c = 0; c < columns.length; c++) {
      for (var d = 0; d < depths[c]; d++) {
        if (idx >= items.length) break;
        placements.add(
          InitialPlacement(
            itemId: items[idx++],
            shelfId: columns[c].shelfId,
            slot: columns[c].slot,
            depth: d,
          ),
        );
      }
    }
    return placements;
  }

  static bool _hasInstantFrontMatch(
    List<InitialPlacement> placements,
    int shelfCount,
    int slots,
  ) {
    // Front = depth 0 only
    final fronts = List.generate(shelfCount, (_) => List<String?>.filled(slots, null));
    for (final p in placements) {
      if (p.depth != 0) continue;
      if (p.shelfId < 1 || p.shelfId > shelfCount) continue;
      if (p.slot < 0 || p.slot >= slots) continue;
      fronts[p.shelfId - 1][p.slot] = p.itemId.split('_').first;
    }
    for (final row in fronts) {
      if (row.any((e) => e == null)) continue;
      if (row[0] == row[1] && row[1] == row[2]) return true;
    }
    return false;
  }

  static int _timeFor(LevelDifficulty d, int itemCount, int maxDepth) {
    final base = (itemCount * (3.2 + maxDepth * 0.4)).round() + 55;
    switch (d) {
      case LevelDifficulty.easy:
      case LevelDifficulty.rest:
        return (base * 1.55).round().clamp(100, 320);
      case LevelDifficulty.hard:
        return (base * 1.05).round().clamp(80, 260);
      case LevelDifficulty.tricky:
        return base.clamp(75, 250);
      case LevelDifficulty.boss:
        return (base * 0.95).round().clamp(110, 340);
      case LevelDifficulty.standard:
        return (base * 1.2).round().clamp(90, 280);
    }
  }

  static _Cfg _configFor(int levelId) {
    // Align board size with PRD bands; depth starts at lvl 11 for hidden row
    if (levelId <= 5) {
      return const _Cfg(
        typeCount: 3,
        setsPerType: 1,
        filledShelves: 3,
        bufferShelves: 2,
        maxDepth: 1,
      );
    }
    if (levelId <= 10) {
      return const _Cfg(
        typeCount: 3,
        setsPerType: 2,
        filledShelves: 4,
        bufferShelves: 2,
        maxDepth: 1,
      );
    }
    if (levelId <= 15) {
      return const _Cfg(
        typeCount: 4,
        setsPerType: 2,
        filledShelves: 5,
        bufferShelves: 2,
        maxDepth: 2,
      );
    }
    if (levelId <= 25) {
      return const _Cfg(
        typeCount: 5,
        setsPerType: 2,
        filledShelves: 6,
        bufferShelves: 2,
        maxDepth: 2,
      );
    }
    if (levelId <= 50) {
      return const _Cfg(
        typeCount: 5,
        setsPerType: 2,
        filledShelves: 7,
        bufferShelves: 2,
        maxDepth: 2,
      );
    }
    if (levelId <= 75) {
      return const _Cfg(
        typeCount: 6,
        setsPerType: 2,
        filledShelves: 8,
        bufferShelves: 3,
        maxDepth: 3,
      );
    }
    return const _Cfg(
      typeCount: 6,
      setsPerType: 3,
      filledShelves: 9,
      bufferShelves: 3,
      maxDepth: 3,
    );
  }
}

class _Cfg {
  final int typeCount;
  final int setsPerType;
  final int filledShelves;
  final int bufferShelves;
  final int maxDepth;

  const _Cfg({
    required this.typeCount,
    required this.setsPerType,
    required this.filledShelves,
    required this.bufferShelves,
    required this.maxDepth,
  });
}
