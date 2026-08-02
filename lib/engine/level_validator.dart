import '../models/item.dart';
import '../models/level_data.dart';
import 'level_shapes.dart';
import 'mechanics/conveyor_tray.dart';
import 'mechanics/mechanic_ids.dart';

/// Fairness / solvability checks for authored and generated levels.
abstract final class LevelValidator {
  static const double minSecondsPerItem = 1.5;

  /// Returns human-readable problems, or an empty list when the level is ok.
  static List<String> problems(LevelData level) {
    final out = <String>[];

    try {
      LevelShapes.validate(
        level.layout.isNotEmpty
            ? level.layout
            : LevelData.defaultLayout(level.shelfCount),
      );
    } catch (e) {
      out.add('layout: $e');
    }

    final layout = level.layout.isNotEmpty
        ? level.layout
        : LevelData.defaultLayout(level.shelfCount);
    final boxes = LevelShapes.boxCount(layout);
    if (level.shelfCount != boxes) {
      out.add('shelfCount ${level.shelfCount} != layout boxes $boxes');
    }

    if (level.trayCount > ConveyorTrayMechanic.maxTrays) {
      out.add(
        'trayCount ${level.trayCount} > ${ConveyorTrayMechanic.maxTrays}',
      );
    }
    if (level.trayCount > 0 &&
        !level.mechanics.contains(MechanicIds.conveyorTray)) {
      out.add('trays present but ${MechanicIds.conveyorTray} is not enabled');
    }

    final typeCounts = <String, int>{};
    final frontByShelf = <int, List<String?>>{};
    for (final p in level.initialPlacement) {
      final type = GameItem.fromId(p.itemId).type;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      if (p.depth == 0) {
        final slots = frontByShelf.putIfAbsent(
          p.shelfId,
          () => List<String?>.filled(level.slotsPerShelf, null),
        );
        if (p.slot >= 0 && p.slot < slots.length) {
          slots[p.slot] = type;
        }
      }
    }

    for (final e in typeCounts.entries) {
      if (e.value % 3 != 0) {
        out.add('type ${e.key} count ${e.value} is not a multiple of 3');
      }
    }

    for (final e in frontByShelf.entries) {
      final filled = e.value.whereType<String>().toList();
      if (filled.length == level.slotsPerShelf &&
          filled.toSet().length == 1) {
        out.add('shelf ${e.key} starts fully matched');
      }
    }

    var freeFront = 0;
    final emptyBoxes = <int>[];
    for (var id = 1; id <= boxes; id++) {
      final slots = frontByShelf[id];
      if (slots == null) {
        freeFront += level.slotsPerShelf;
        emptyBoxes.add(id);
      } else {
        freeFront += slots.where((s) => s == null).length;
        if (slots.every((s) => s == null)) emptyBoxes.add(id);
      }
    }
    if (freeFront < 2) {
      out.add('only $freeFront free front slots (need >= 2)');
    }
    // A cupboard that opens with a bare box looks unfinished; every box holds
    // something at the start.
    if (emptyBoxes.isNotEmpty) {
      out.add('boxes start empty: $emptyBoxes');
    }
    for (var t = 0; t < level.trayCount; t++) {
      final slots = frontByShelf[boxes + 1 + t];
      if (slots == null || slots.every((s) => s == null)) {
        out.add('tray ${t + 1} starts empty');
      }
    }

    // Some trays roll past with room on them, otherwise a good picked off the
    // cupboard has nowhere to ride.
    if (level.trayCount > 0) {
      var trayWithRoom = 0;
      for (var t = 0; t < level.trayCount; t++) {
        final slots = frontByShelf[boxes + 1 + t];
        if (slots == null || slots.any((s) => s == null)) trayWithRoom += 1;
      }
      if (trayWithRoom == 0) {
        out.add('no tray starts with a free place');
      }
    }

    final maxShelfId = boxes + level.trayCount;
    for (final p in level.initialPlacement) {
      if (p.shelfId < 1 || p.shelfId > maxShelfId) {
        out.add('placement on unknown shelf ${p.shelfId}');
        break;
      }
    }

    final trayCapacity = level.trayCount * level.slotsPerShelf;
    final capacity = boxes * level.slotsPerShelf + trayCapacity;
    if (level.initialPlacement.length > capacity) {
      final maxDepth = level.initialPlacement.fold<int>(
        0,
        (m, p) => p.depth > m ? p.depth : m,
      );
      final layeredCap =
          boxes * level.slotsPerShelf * (maxDepth + 1) + trayCapacity;
      if (level.initialPlacement.length > layeredCap) {
        out.add(
          'items ${level.initialPlacement.length} exceed capacity $layeredCap',
        );
      }
    }

    final itemCount = level.initialPlacement.length;
    final minTime = (itemCount * minSecondsPerItem).ceil();
    if (level.timeLimit > 0 && level.timeLimit < minTime) {
      out.add(
        'timeLimit ${level.timeLimit}s < $minTime s for $itemCount items',
      );
    }

    return out;
  }

  static bool isValid(LevelData level) => problems(level).isEmpty;

  /// How much pressure a level puts on the player, used to prove the campaign
  /// only ever gets harder.
  ///
  /// What makes a board hard is how much of it is hidden, how deep the stacks
  /// go, how fast the belt runs and how little time there is per good. Sheer
  /// stock counts too, but only lightly: a big board is longer work, not
  /// necessarily harder work.
  static double pressure(LevelData level) {
    final goods = level.initialPlacement.length;
    if (goods == 0) return 0;
    var hidden = 0;
    var maxDepth = 0;
    final types = <String>{};
    for (final p in level.initialPlacement) {
      if (p.depth > 0) hidden += 1;
      if (p.depth > maxDepth) maxDepth = p.depth;
      types.add(GameItem.fromId(p.itemId).type);
    }
    final speed =
        ((level.mechanicConfig['conveyorTray'] as Map?)?['speed'] as num?)
                ?.toDouble() ??
            0;
    final secondsPerGood = level.timeLimit / goods;
    final clock = (5.0 - secondsPerGood).clamp(0.0, 5.0);
    final hiddenShare = hidden / goods;

    return goods * 0.6 +
        hidden * 0.9 +
        hiddenShare * 40 +
        maxDepth * 8 +
        types.length * 0.4 +
        level.trayCount * 4 +
        speed * 55 +
        clock * 20;
  }
}
