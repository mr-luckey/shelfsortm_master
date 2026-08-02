import '../models/item.dart';
import '../models/level_data.dart';
import '../models/shelf.dart';

/// Holds the layers stacked behind each box.
///
/// Layer 0 is placed on the board at level start; every deeper layer waits here
/// and only slides forward once its box is emptied.
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
      final placements = byShelf[shelf.shelfId] ?? const [];

      // One wave per depth — a layer keeps its slot positions.
      final byDepth = <int, List<GameItem?>>{};
      for (final p in placements) {
        if (p.slot < 0 || p.slot >= shelf.slotCount) continue;
        final wave = byDepth.putIfAbsent(
          p.depth,
          () => List<GameItem?>.filled(shelf.slotCount, null),
        );
        wave[p.slot] = GameItem.fromId(p.itemId);
      }

      final depths = byDepth.keys.toList()..sort();
      final waves = <List<GameItem?>>[
        for (final d in depths)
          if (byDepth[d]!.any((e) => e != null)) byDepth[d]!,
      ];
      if (waves.isEmpty) {
        waves.add(List<GameItem?>.filled(shelf.slotCount, null));
      }

      _wavesByShelfId[shelf.shelfId] = waves;
      _cursorByShelfId[shelf.shelfId] = 1; // layer 0 already on the board
    }
  }

  /// The layer waiting directly behind [shelfId], if any (used for the shadow).
  List<GameItem?>? nextWaveFor(int shelfId) {
    final waves = _wavesByShelfId[shelfId];
    if (waves == null) return null;
    final cursor = _cursorByShelfId[shelfId] ?? 1;
    if (cursor >= waves.length) return null;
    return waves[cursor];
  }

  /// Layers still stacked behind [shelfId].
  int layersLeftFor(int shelfId) {
    final waves = _wavesByShelfId[shelfId];
    if (waves == null) return 0;
    final cursor = _cursorByShelfId[shelfId] ?? 1;
    return (waves.length - cursor).clamp(0, waves.length);
  }

  /// Box emptied: queue the layer behind it (not applied until animation).
  bool queueNextWave(int shelfIndex, Shelf shelf) {
    final shelfId = shelf.shelfId;
    final waves = _wavesByShelfId[shelfId] ?? [];
    final cursor = _cursorByShelfId[shelfId] ?? 1;

    if (cursor >= waves.length) {
      _finishedShelfIndices.add(shelfIndex);
      return false;
    }

    _pendingByShelfIndex[shelfIndex] = List<GameItem?>.from(waves[cursor]);
    _cursorByShelfId[shelfId] = cursor + 1;
    return true;
  }

  List<GameItem?>? takePendingWave(int shelfIndex) {
    return _pendingByShelfIndex.remove(shelfIndex);
  }

  bool hasPendingWave(int shelfIndex) =>
      _pendingByShelfIndex.containsKey(shelfIndex);

  Shelf applyWave(Shelf shelf, List<GameItem?> wave) {
    final slots = List<ShelfSlot>.generate(shelf.slotCount, (i) {
      final item = i < wave.length ? wave[i] : null;
      return item == null ? const ShelfSlot() : ShelfSlot.front(item);
    });
    return shelf.copyWith(slots: slots);
  }

  Map<String, dynamic> toJson() => {
        'cursor': _cursorByShelfId.map((k, v) => MapEntry(k.toString(), v)),
        'finished': _finishedShelfIndices.toList(),
        'pending': _pendingByShelfIndex.map(
          (k, v) => MapEntry(
            k.toString(),
            v.map((item) => item?.toJson()).toList(),
          ),
        ),
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
    _pendingByShelfIndex.clear();
    final pending = json['pending'];
    if (pending is Map) {
      for (final e in pending.entries) {
        final key = int.parse(e.key.toString());
        final list = (e.value as List?) ?? const [];
        _pendingByShelfIndex[key] = [
          for (final item in list)
            item == null
                ? null
                : GameItem.fromJson(Map<String, dynamic>.from(item as Map)),
        ];
      }
    }
  }
}
