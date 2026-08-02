import 'dart:convert';

import 'package:flutter/services.dart';

import '../engine/level_generator.dart';
import '../models/level_data.dart';
import '../models/player_progress.dart';

class LevelRepository {
  LevelRepository._();
  static final LevelRepository instance = LevelRepository._();

  static const int _cacheLimit = 8;

  final Map<int, LevelData> _cache = {};
  final Map<int, LevelData> _authored = {};
  bool _preloaded = false;

  int get totalLevels => PlayerProgress.totalLevels;

  /// Loads the authored level index and JSON files under assets/levels/.
  Future<void> preload() async {
    if (_preloaded) return;
    _preloaded = true;
    try {
      final raw = await rootBundle.loadString('assets/levels/index.json');
      final decoded = jsonDecode(raw);
      final ids = <int>[];
      if (decoded is Map && decoded['authored'] is List) {
        for (final e in decoded['authored'] as List) {
          ids.add(e as int);
        }
      } else if (decoded is List) {
        for (final e in decoded) {
          ids.add(e as int);
        }
      }
      for (final id in ids) {
        final path =
            'assets/levels/level_${id.toString().padLeft(3, '0')}.json';
        try {
          final body = await rootBundle.loadString(path);
          final level =
              LevelData.fromJson(jsonDecode(body) as Map<String, dynamic>);
          _authored[id] = level;
        } catch (_) {
          // Missing or invalid authored file — fall back to generator.
        }
      }
    } catch (_) {
      // No index yet — every level is generated.
    }
  }

  LevelData getLevel(int levelId) {
    final authored = _authored[levelId];
    if (authored != null) return authored;

    final cached = _cache.remove(levelId);
    if (cached != null) {
      _cache[levelId] = cached;
      return cached;
    }
    final level = LevelGenerator.generate(levelId);
    _cache[levelId] = level;
    while (_cache.length > _cacheLimit) {
      _cache.remove(_cache.keys.first);
    }
    return level;
  }

  LevelData dailyChallenge(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final base = LevelGenerator.generate((seed % 200) + 8);
    return LevelData(
      levelId: 9000 + (seed % 1000),
      themeRoom: base.themeRoom,
      difficulty: 'hard',
      timeLimit: (base.timeLimit * 0.9).round(),
      shelfCount: base.shelfCount,
      slotsPerShelf: 3,
      bufferShelves: base.bufferShelves,
      initialPlacement: base.initialPlacement,
      optimalMoves: base.optimalMoves,
      levelTint: base.levelTint,
      layout: base.layout,
      mechanics: base.mechanics,
      mechanicConfig: base.mechanicConfig,
      seed: seed,
      starThresholds: base.starThresholds,
    );
  }
}
