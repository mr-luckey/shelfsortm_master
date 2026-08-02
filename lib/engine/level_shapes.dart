/// Named cupboard silhouettes. Every shape fits inside 4 columns × 10 rows.
///
/// Layout cells are 1-based shelf ids. `0` is a visual hole (no compartment).
abstract final class LevelShapes {
  static const int maxCols = 4;
  static const int maxRows = 10;

  static const Map<String, List<List<int>>> all = {
    'pair': [
      [1, 2],
    ],
    'trio': [
      [1, 2, 3],
    ],
    'row4': [
      [1, 2, 3, 4],
    ],
    'grid2x2': [
      [1, 2],
      [3, 4],
    ],
    'grid3x2': [
      [1, 2, 3],
      [4, 5, 6],
    ],
    'grid3x3': [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
    ],
    'grid4x2': [
      [1, 2, 3, 4],
      [5, 6, 7, 8],
    ],
    'grid4x3': [
      [1, 2, 3, 4],
      [5, 6, 7, 8],
      [9, 10, 11, 12],
    ],
    'grid4x4': [
      [1, 2, 3, 4],
      [5, 6, 7, 8],
      [9, 10, 11, 12],
      [13, 14, 15, 16],
    ],
    'stair7': [
      [1, 2, 3],
      [4, 5, 6, 7],
    ],
    'tallNarrow': [
      [1, 2],
      [3, 4],
      [5, 6],
      [7, 8],
    ],
    'lShape': [
      [1, 2, 3],
      [4, 0, 0],
      [5, 0, 0],
    ],
    'tShape': [
      [1, 2, 3],
      [0, 4, 0],
      [0, 5, 0],
    ],
    'uShape': [
      [1, 0, 2],
      [3, 4, 5],
    ],
    'pyramid': [
      [0, 1, 0],
      [2, 3, 4],
      [5, 6, 7, 8],
    ],
    'offset': [
      [0, 1, 2],
      [3, 4, 0],
    ],
    'split': [
      [1, 2],
      [0, 0],
      [3, 4],
    ],
    'asymmetric8': [
      [1, 2, 3, 0],
      [4, 5, 6, 7],
      [0, 8, 0, 0],
    ],
    'wide10': [
      [1, 2, 3, 4],
      [5, 6, 7, 8],
      [9, 10, 0, 0],
    ],
    'medium12': [
      [1, 2, 3, 4],
      [5, 6, 7, 8],
      [9, 10, 11, 12],
    ],
  };

  static List<List<int>> byId(String id) {
    final layout = all[id];
    if (layout == null) {
      throw ArgumentError('Unknown shape id: $id');
    }
    return layout.map((row) => List<int>.from(row)).toList();
  }

  /// Non-zero shelf ids in row-major order.
  static int boxCount(List<List<int>> layout) {
    var n = 0;
    for (final row in layout) {
      for (final cell in row) {
        if (cell > 0) n += 1;
      }
    }
    return n;
  }

  static int colCount(List<List<int>> layout) {
    var cols = 0;
    for (final row in layout) {
      if (row.length > cols) cols = row.length;
    }
    return cols;
  }

  /// Pads every row to the same column count with trailing zeros.
  static List<List<int>> normalize(List<List<int>> layout) {
    final cols = colCount(layout);
    return [
      for (final row in layout)
        [
          ...row,
          for (var i = row.length; i < cols; i++) 0,
        ],
    ];
  }

  /// Throws if the layout exceeds the hard board limit or has bad ids.
  static void validate(List<List<int>> layout) {
    if (layout.isEmpty) {
      throw StateError('layout is empty');
    }
    if (layout.length > maxRows) {
      throw StateError('layout has ${layout.length} rows (max $maxRows)');
    }
    final cols = colCount(layout);
    if (cols > maxCols) {
      throw StateError('layout has $cols columns (max $maxCols)');
    }
    final seen = <int>{};
    for (final row in layout) {
      for (final cell in row) {
        if (cell == 0) continue;
        if (cell < 0) {
          throw StateError('negative shelf id $cell');
        }
        if (!seen.add(cell)) {
          throw StateError('duplicate shelf id $cell');
        }
      }
    }
    if (seen.isEmpty) {
      throw StateError('layout has no compartments');
    }
    final ids = seen.toList()..sort();
    for (var i = 0; i < ids.length; i++) {
      if (ids[i] != i + 1) {
        throw StateError('shelf ids must be contiguous from 1, got $ids');
      }
    }
  }
}
