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
    expect(LevelPlan.forLevel(1).boxes, 3);
    expect(LevelPlan.forLevel(2).boxes, 4);
    expect(LevelPlan.forLevel(3).boxes, 6);
    expect(LevelPlan.forLevel(4).boxes, 8);
    expect(LevelPlan.forLevel(5).boxes, 9);
    expect(LevelPlan.forLevel(6).boxes, 12);

    final generated = [
      for (var id = 1; id <= 6; id++) LevelGenerator.generate(id),
    ];
    expect(generated.map((l) => l.shelfCount).toList(), [3, 4, 6, 8, 9, 12]);
  });

  test('the cupboard never shrinks while the campaign is still growing', () {
    for (var id = 2; id <= 20; id++) {
      expect(
        LevelPlan.forLevel(id).boxes,
        greaterThanOrEqualTo(LevelPlan.forLevel(id - 1).boxes),
        reason: 'level $id has a smaller cupboard than ${id - 1}',
      );
    }
  });

  test('cabinets grow through the campaign without repeating a size', () {
    for (var id = 3; id <= 30; id++) {
      final a = LevelPlan.forLevel(id - 2);
      final b = LevelPlan.forLevel(id - 1);
      final c = LevelPlan.forLevel(id);
      final same = a.shapeId == b.shapeId &&
          b.shapeId == c.shapeId &&
          a.layers == b.layers &&
          b.layers == c.layers;
      expect(same, isFalse, reason: 'levels ${id - 2}-$id feel alike');
    }
  });

  test('holes are allowed and normalize pads short rows', () {
    final layout = LevelShapes.byId('podium4x5');
    expect(layout.any((row) => row.contains(0)), isTrue);
    final normalized = LevelShapes.normalize(layout);
    final cols = LevelShapes.colCount(normalized);
    expect(normalized.every((row) => row.length == cols), isTrue);
  });
}
