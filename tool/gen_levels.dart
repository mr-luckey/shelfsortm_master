/// Regenerates assets/levels from LevelGenerator.
import 'dart:convert';
import 'dart:io';

import 'package:shelfsortm_master/engine/level_generator.dart';

void main() {
  for (var levelId = 1; levelId <= 250; levelId++) {
    final level = LevelGenerator.generate(levelId);
    final path =
        'assets/levels/level_${levelId.toString().padLeft(3, '0')}.json';
    File(path).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(level.toJson()),
    );
    stdout.writeln(
      'Wrote $path items=${level.initialPlacement.length} '
      'shelves=${level.shelfCount} depthMax='
      '${level.initialPlacement.fold<int>(0, (m, p) => p.depth > m ? p.depth : m)}',
    );
  }
}
