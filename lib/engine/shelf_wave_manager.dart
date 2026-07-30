import '../models/item.dart';
import '../models/level_data.dart';
import '../models/shelf.dart';

/// Builds per-shelf item waves for Goods Sort close-and-replenish flow.
class ShelfWaveManager {
  final Map<int, List<List<GameItem?>>> _wavesByShelfId = {};
  final Map<int, int> _cursorByShelfId = {};
  final Map<int, List<GameItem?>> _pendingByShelfIndex = {};
  final Set<int> _finishedShelfIndices = {};

  Map<int, List<GameItem?>> get pendingByShelfIndex =>
      Map.unmodifiable(_pendingByShelfIndex);

  Set<int> get finishedShelfIndices => Set.unmodifiable(_finishedShelfIndices);

  int get wavesRemaining {
    var n = _pendingByShelfIndex.length;
    for (final e in _wavesByShelfId.entries) {
      final cur = _cursorByShelfId[e.key] ?? 1;
      if (cur < e.value.length) n += e.value.length - cur;
    }
    return n;
  }

  void initialize(LevelData level, List<Shelf> shelves) {
    _wavesByShelfId.clear();
    _cursorByShelfId.clear();
    _pendingByShelfIndex.clear();
    _finishedShelfIndices.clear();

    final byShelf = <int, List<InitialPlacement>>{};
    for (final p in level.initialPlacement) {
      byShelf.putIfAbsent(p.shelfId, () => []).add(p);
    }

    for (final shelf in shelves) {
      final placements = byShelf[shelf.shelfId] ?? [];
      placements.sort((a, b) {
        final d = a.depth.compareTo(b.depth);
        return d != 0 ? d : a.slot.compareTo(b.slot);
      });

      final items =
          placements.map((p) => GameItem.fromId(p.itemId)).toList();
      final waves = <List<GameItem?>>[];
      var i = 0;
      while (i < items.length) {
        final wave = List<GameItem?>.filled(shelf.slotCount, null);
        for (var s = 0; s < shelf.slotCount && i < items.length; s++) {
          wave[s] = items[i++];
        }
        waves.add(wave);
      }
      if (waves.isEmpty) {
        waves.add(List<GameItem?>.filled(shelf.slotCount, null));
      }

      _wavesByShelfId[shelf.shelfId] = waves;
      _cursorByShelfId[shelf.shelfId] = 1; // wave 0 already on board
    }
  }

  /// After triple match: queue the next wave (not applied until animation).
  bool queueNextWave(int shelfIndex, Shelf shelf) {
    final shelfId = shelf.shelfId;
    final waves = _wavesByShelfId[shelfId] ?? [];
    final cursor = _cursorByShelfId[shelfId] ?? 1;

    if (cursor >= waves.length) {
      _finishedShelfIndices.add(shelfIndex);
      return false;
    }

    _pendingByShelfIndex[shelfIndex] =
        List<GameItem?>.from(waves[cursor]);
    _cursorByShelfId[shelfId] = cursor + 1;
    return true;
  }

  List<GameItem?>? takePendingWave(int shelfIndex) {
    return _pendingByShelfIndex.remove(shelfIndex);
  }

  bool hasPendingWave(int shelfIndex) =>
      _pendingByShelfIndex.containsKey(shelfIndex);

  Shelf applyWave(Shelf shelf, List<GameItem?> wave) {
    final slots = List<ShelfSlot>.generate(wave.length, (i) {
      final item = wave[i];
      return item == null ? const ShelfSlot() : ShelfSlot.front(item);
    });
    return shelf.copyWith(slots: slots);
  }

  Map<String, dynamic> toJson() => {
        'cursor': _cursorByShelfId.map((k, v) => MapEntry(k.toString(), v)),
        'finished': _finishedShelfIndices.toList(),
      };

  void loadJson(Map<String, dynamic> json) {
    _cursorByShelfId.clear();
    final c = json['cursor'] as Map<String, dynamic>? ?? {};
    for (final e in c.entries) {
      _cursorByShelfId[int.parse(e.key)] = e.value as int;
    }
    _finishedShelfIndices
      ..clear()
      ..addAll((json['finished'] as List?)?.cast<int>() ?? []);
  }
}
