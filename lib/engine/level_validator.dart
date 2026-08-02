import '../models/item.dart';
import '../models/level_data.dart';
import 'level_shapes.dart';
import 'mechanics/conveyor_tray.dart';
import 'mechanics/mechanic_ids.dart';

/// Fairness / solvability checks for authored and generated levels.
abstract final class LevelValidator {
  static const double minSecondsPerItem = 2.5;

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
    for (var id = 1; id <= boxes; id++) {
      final slots = frontByShelf[id];
      if (slots == null) {
        freeFront += level.slotsPerShelf;
      } else {
        freeFront += slots.where((s) => s == null).length;
      }
    }
    if (freeFront < 2) {
      out.add('only $freeFront free front slots (need >= 2)');
    }

    // A tray must roll past with room on it, otherwise a good picked off the
    // cupboard has nowhere to ride.
    for (var t = 0; t < level.trayCount; t++) {
      final slots = frontByShelf[boxes + 1 + t];
      if (slots == null) continue;
      if (!slots.any((s) => s == null)) {
        out.add('tray ${t + 1} starts with no free place');
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
}
