import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsortm_master/engine/level_generator.dart';
import 'package:shelfsortm_master/engine/level_plan.dart';
import 'package:shelfsortm_master/engine/level_shapes.dart';

void main() {
  test('every named shape fits inside 4x10 with contiguous ids', () {
    for (final e in LevelShapes.all.entries) {
      final layout = e.value;
      expect(
        () => LevelShapes.validate(layout),
        returnsNormally,
        reason: e.key,
      );
      expect(layout.length, lessThanOrEqualTo(LevelShapes.maxRows), reason: e.key);
      expect(
        LevelShapes.colCount(layout),
        lessThanOrEqualTo(LevelShapes.maxCols),
        reason: e.key,
      );
      final boxes = LevelShapes.boxCount(layout);
      expect(boxes, greaterThan(0), reason: e.key);
      final ids = [
        for (final row in layout)
          for (final cell in row)
            if (cell > 0) cell,
      ]..sort();
      expect(ids, List.generate(boxes, (i) => i + 1), reason: e.key);
    }
  });

  test('early campaign layouts match the progression examples', () {
    expect(LevelPlan.forLevel(1).boxes, 2);
    expect(LevelPlan.forLevel(2).boxes, 3);
    expect(LevelPlan.forLevel(3).boxes, 6);
    expect(LevelPlan.forLevel(4).boxes, 7);

    final generated = [
      for (var id = 1; id <= 4; id++) LevelGenerator.generate(id),
    ];
    expect(generated[0].shelfCount, 2);
    expect(generated[1].shelfCount, 3);
    expect(generated[2].shelfCount, 6);
    expect(generated[3].shelfCount, 7);
  });

  test('holes are allowed and normalize pads short rows', () {
    final layout = LevelShapes.byId('lShape');
    expect(layout.any((row) => row.contains(0)), isTrue);
    final normalized = LevelShapes.normalize(layout);
    final cols = LevelShapes.colCount(normalized);
    expect(normalized.every((row) => row.length == cols), isTrue);
  });
}
