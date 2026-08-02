import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsortm_master/engine/level_generator.dart';
import 'package:shelfsortm_master/engine/level_validator.dart';
import 'package:shelfsortm_master/models/level_data.dart';

void main() {
  test('authored level files parse and stay fair', () {
    final index = jsonDecode(File('assets/levels/index.json').readAsStringSync())
        as Map<String, dynamic>;
    final ids = (index['authored'] as List).cast<int>();
    expect(ids, isNotEmpty);

    for (final id in ids) {
      final path = 'assets/levels/level_${id.toString().padLeft(3, '0')}.json';
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'missing $path');
      final level = LevelData.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
      expect(level.levelId, id);
      expect(LevelValidator.problems(level), isEmpty, reason: 'Level $id');
      expect(level.initialPlacement, isNotEmpty, reason: 'Level $id empty');
    }
  });

  test('generated levels 1-200 pass the fairness validator', () {
    for (var id = 1; id <= 200; id++) {
      final level = LevelGenerator.generate(id);
      final problems = LevelValidator.problems(level);
      expect(problems, isEmpty, reason: 'Level $id: $problems');

      final counts = <String, int>{};
      for (final p in level.initialPlacement) {
        final type = p.itemId.split('_').first;
        counts[type] = (counts[type] ?? 0) + 1;
      }
      for (final e in counts.entries) {
        expect(e.value % 3, 0, reason: 'Level $id type ${e.key}');
      }
    }
  });

  test('validator rejects a pre-matched full box', () {
    final base = LevelGenerator.generate(3);
    final forged = [
      for (var slot = 0; slot < 3; slot++)
        InitialPlacement(
          itemId: 'icecream_red_00${slot + 1}',
          shelfId: 1,
          slot: slot,
        ),
      ...base.initialPlacement.where((p) => p.shelfId != 1 || p.depth != 0),
    ];
    final level = LevelData(
      levelId: base.levelId,
      themeRoom: base.themeRoom,
      difficulty: base.difficulty,
      timeLimit: base.timeLimit,
      shelfCount: base.shelfCount,
      slotsPerShelf: base.slotsPerShelf,
      initialPlacement: forged,
      starThresholds: base.starThresholds,
      layout: base.layout,
    );
    expect(LevelValidator.problems(level), isNotEmpty);
  });
}
