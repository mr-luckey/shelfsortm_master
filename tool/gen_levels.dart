// Writes authored early levels (1-20) and assets/levels/index.json.
//
// Run: `dart run tool/gen_levels.dart` from the project root.
import 'dart:convert';
import 'dart:io';

import 'package:shelfsortm_master/engine/level_generator.dart';
import 'package:shelfsortm_master/engine/level_validator.dart';

void main() {
  final dir = Directory('assets/levels');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  for (final entity in dir.listSync()) {
    if (entity is File && entity.path.endsWith('.json')) {
      entity.deleteSync();
    }
  }

  final authored = <int>[];
  for (var levelId = 1; levelId <= 20; levelId++) {
    final level = LevelGenerator.generate(levelId);
    final problems = LevelValidator.problems(level);
    if (problems.isNotEmpty) {
      stderr.writeln('Level $levelId invalid: $problems');
      exitCode = 1;
    }
    final path =
        'assets/levels/level_${levelId.toString().padLeft(3, '0')}.json';
    File(path).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(level.toJson()),
    );
    authored.add(levelId);
    stdout.writeln(
      'Wrote $path boxes=${level.shelfCount} '
      'trays=${level.trayCount} '
      'items=${level.initialPlacement.length} '
      'time=${level.timeLimit}',
    );
  }

  File('assets/levels/index.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({'authored': authored}),
  );
  stdout.writeln('Wrote assets/levels/index.json (${authored.length} levels)');
}
