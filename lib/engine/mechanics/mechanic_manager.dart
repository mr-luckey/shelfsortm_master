import '../match_engine.dart';
import 'chain_release.dart';
import 'conveyor_shelf.dart';
import 'frozen_item.dart';
import 'hidden_back_row.dart';
import 'level_mechanic.dart';
import 'locked_item.dart';
import 'mechanic_ids.dart';
import 'moving_bottom_tray.dart';
import 'moving_divider.dart';
import 'mystery_box.dart';
import 'rotating_tray.dart';
import 'sliding_shelf.dart';
import 'stacked_items.dart';

/// Config key in mechanicConfig for each mechanic id.
String configKeyFor(String mechanicId) {
  return switch (mechanicId) {
    MechanicIds.hiddenBackRow => 'hiddenBackRow',
    MechanicIds.movingBottomTray => 'movingBottomTray',
    MechanicIds.slidingShelves => 'slidingShelves',
    MechanicIds.rotatingTray => 'rotatingTray',
    MechanicIds.conveyorShelf => 'conveyorShelf',
    MechanicIds.lockedItems => 'lockedItems',
    MechanicIds.mysteryBoxes => 'mysteryBoxes',
    MechanicIds.stackedItems => 'stackedItems',
    MechanicIds.frozenItems => 'frozenItems',
    MechanicIds.movingDivider => 'movingDivider',
    MechanicIds.chainRelease => 'chainRelease',
    _ => mechanicId,
  };
}

LevelMechanic? createMechanic(String id) {
  return switch (id) {
    MechanicIds.hiddenBackRow => HiddenBackRowMechanic(),
    MechanicIds.movingBottomTray => MovingBottomTrayMechanic(),
    MechanicIds.slidingShelves => SlidingShelfMechanic(),
    MechanicIds.rotatingTray => RotatingTrayMechanic(),
    MechanicIds.conveyorShelf => ConveyorShelfMechanic(),
    MechanicIds.lockedItems => LockedItemMechanic(),
    MechanicIds.mysteryBoxes => MysteryBoxMechanic(),
    MechanicIds.stackedItems => StackedItemMechanic(),
    MechanicIds.frozenItems => FrozenItemMechanic(),
    MechanicIds.movingDivider => MovingDividerMechanic(),
    MechanicIds.chainRelease => ChainReleaseMechanic(),
    _ => null,
  };
}

/// Registry that owns all active mechanics for a level.
class MechanicManager {
  final List<LevelMechanic> mechanics = [];
  bool reducedMotion = false;

  void initialize(MatchEngine engine) {
    dispose();
    final ids = engine.level.mechanics;
    final cfg = engine.level.mechanicConfig;

    for (final id in ids) {
      final m = createMechanic(id);
      if (m == null) continue;
      final key = configKeyFor(id);
      final mcfg = (cfg[key] as Map?)?.cast<String, dynamic>() ??
          (cfg[id] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      m.initialize(engine, mcfg);
      mechanics.add(m);
    }

    // Bind chain release peers
    final chain = ofType<ChainReleaseMechanic>();
    if (chain != null) {
      chain.bindPeers(
        locked: ofType<LockedItemMechanic>(),
        mystery: ofType<MysteryBoxMechanic>(),
        frozen: ofType<FrozenItemMechanic>(),
      );
    }

    for (final m in mechanics) {
      if (m is MovingBottomTrayMechanic) m.reducedMotion = reducedMotion;
      if (m is SlidingShelfMechanic) m.reducedMotion = reducedMotion;
      if (m is RotatingTrayMechanic) m.reducedMotion = reducedMotion;
      if (m is ConveyorShelfMechanic) m.reducedMotion = reducedMotion;
      if (m is MovingDividerMechanic) m.reducedMotion = reducedMotion;
      m.start();
    }
  }

  T? ofType<T extends LevelMechanic>() {
    for (final m in mechanics) {
      if (m is T) return m;
    }
    return null;
  }

  bool has(String id) => mechanics.any((m) => m.id == id);

  void tick(double dt) {
    for (final m in mechanics) {
      m.tick(dt);
    }
  }

  void pause() {
    for (final m in mechanics) {
      m.pause();
    }
  }

  void resume() {
    for (final m in mechanics) {
      m.resume();
    }
  }

  bool validateMove(BoardPos from, BoardPos to) {
    for (final m in mechanics) {
      if (!m.validateMove(from, to)) return false;
    }
    return true;
  }

  bool canInteract(BoardPos pos) {
    for (final m in mechanics) {
      if (!m.canInteract(pos)) return false;
    }
    return true;
  }

  void onMoveCompleted(BoardPos from, BoardPos to) {
    for (final m in mechanics) {
      m.onMoveCompleted(from, to);
    }
  }

  void onShelfCleared(int shelfIndex, String type) {
    for (final m in mechanics) {
      m.onShelfCleared(shelfIndex, type);
    }
  }

  List<String> get objectiveHints {
    final hints = <String>[];
    for (final m in mechanics) {
      final h = m.objectiveHint;
      if (h != null && h.isNotEmpty) hints.add(h);
    }
    return hints;
  }

  Map<String, dynamic> saveState() {
    final out = <String, dynamic>{};
    for (final m in mechanics) {
      out[m.id] = m.saveState();
    }
    return out;
  }

  void loadState(Map<String, dynamic> json) {
    for (final m in mechanics) {
      final s = json[m.id];
      if (s is Map<String, dynamic>) {
        m.loadState(s);
      } else if (s is Map) {
        m.loadState(Map<String, dynamic>.from(s));
      }
    }
  }

  void dispose() {
    for (final m in mechanics) {
      m.dispose();
    }
    mechanics.clear();
  }
}
