import 'package:flutter/material.dart';

import '../../engine/match_engine.dart';

/// The good currently lifted off the board.
@immutable
class HeldGood {
  final BoardPos from;
  final String type;

  /// True when the good was picked off a moving tray.
  final bool fromTray;

  const HeldGood({
    required this.from,
    required this.type,
    this.fromTray = false,
  });
}

/// A part of the board that can hand a good over or take one.
abstract class BoardDropZone {
  /// Place under [global], whether it holds a good or not; null when the point
  /// is outside this zone.
  BoardPos? slotAt(Offset global);

  /// First free place in the box or tray under [global].
  BoardPos? freeSlotAt(Offset global);

  /// Whether the place under [global] belongs to a moving tray.
  bool isTrayAt(Offset global);
}

/// Carries one good between the cupboard and the tray belt.
///
/// Both halves of the board register here, so a drag that starts on a tray can
/// finish inside the cupboard and the other way round.
class BoardDragController {
  final ValueNotifier<HeldGood?> held = ValueNotifier<HeldGood?>(null);
  final ValueNotifier<Offset> finger = ValueNotifier<Offset>(Offset.zero);

  final List<BoardDropZone> _zones = [];

  void register(BoardDropZone zone) {
    if (!_zones.contains(zone)) _zones.add(zone);
  }

  void unregister(BoardDropZone zone) => _zones.remove(zone);

  void begin(HeldGood good, Offset global) {
    finger.value = global;
    held.value = good;
  }

  void moveTo(Offset global) => finger.value = global;

  void end() => held.value = null;

  /// Where a dropped good would land, across every zone.
  BoardPos? dropAt(Offset global) {
    for (final zone in _zones) {
      final pos = zone.freeSlotAt(global);
      if (pos != null) return pos;
    }
    return null;
  }

  bool isTrayAt(Offset global) {
    for (final zone in _zones) {
      if (zone.slotAt(global) != null) return zone.isTrayAt(global);
    }
    return false;
  }

  void dispose() {
    _zones.clear();
    held.dispose();
    finger.dispose();
  }
}
