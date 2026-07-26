import 'dart:convert';

import 'package:flutter/services.dart';

import '../engine/level_generator.dart';
import '../models/level_data.dart';

class LevelRepository {
  LevelRepository._();
  static final LevelRepository instance = LevelRepository._();

  final Map<int, LevelData> _cache = {};
  bool _generated = false;

  Future<void> preload() async {
    if (_generated) return;
    for (var i = 1; i <= 50; i++) {
      final path =
          'assets/levels/level_${i.toString().padLeft(3, '0')}.json';
      try {
        final raw = await rootBundle.loadString(path);
        final json = jsonDecode(raw) as Map<String, dynamic>;
        if (json['initialPlacement'] is List &&
            (json['initialPlacement'] as List).isNotEmpty &&
            (json['slotsPerShelf'] as int? ?? 0) == 3) {
          _cache[i] = LevelData.fromJson(json);
        } else {
          _cache[i] = LevelGenerator.generate(i);
        }
      } catch (_) {
        _cache[i] = LevelGenerator.generate(i);
      }
    }
    _generated = true;
  }

  LevelData getLevel(int levelId) {
    if (_cache.containsKey(levelId)) return _cache[levelId]!;
    final level = LevelGenerator.generate(levelId);
    _cache[levelId] = level;
    return level;
  }

  LevelData dailyChallenge(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final base = LevelGenerator.generate((seed % 40) + 8);
    return LevelData(
      levelId: 9000 + (seed % 1000),
      themeRoom: 'kitchen',
      difficulty: 'hard',
      timeLimit: (base.timeLimit * 0.9).round(),
      shelfCount: base.shelfCount,
      slotsPerShelf: 3,
      bufferShelves: base.bufferShelves,
      initialPlacement: base.initialPlacement,
      starThresholds: base.starThresholds,
      optimalMoves: base.optimalMoves,
    );
  }

  int get totalLevels => 50;
}
