/// Named cupboard silhouettes. Every shape fits inside 4 columns × 10 rows.
///
/// Layout cells are 1-based shelf ids. `0` is a visual hole (no compartment).
/// Shapes are plain rectangular cabinets apart from one symmetrical design with
/// a narrower base, so a board always reads as joinery instead of a random blob.
abstract final class LevelShapes {
  static const int maxCols = 4;
  static const int maxRows = 10;

  /// Cabinet sizes the campaign draws from, as `cols x rows`.
  static const List<List<int>> gridSizes = [
    [2, 1],
    [3, 1],
    [2, 2],
    [3, 2],
    [4, 2],
    [3, 3],
    [4, 3],
    [3, 4],
    [4, 4],
    [3, 5],
    [4, 5],
    [3, 6],
    [4, 6],
    [3, 7],
    [4, 7],
    [3, 8],
    [4, 8],
    [3, 9],
    [4, 9],
    [3, 10],
    [4, 10],
  ];

  /// Cabinets that are not a plain rectangle but still look manufactured:
  /// a full carcass with a narrower, centred base section.
  static const Map<String, List<List<int>>> special = {
    'duo': [
      [1, 2],
    ],
    'trio': [
      [1, 2, 3],
    ],
    'podium4x5': [
      [1, 2, 3, 4],
      [5, 6, 7, 8],
      [9, 10, 11, 12],
      [13, 14, 15, 16],
      [0, 17, 18, 0],
    ],
  };

  /// Rectangular cabinet, ids running left to right and top to bottom.
  static List<List<int>> grid(int cols, int rows) {
    if (cols < 1 || cols > maxCols) {
      throw ArgumentError('cols $cols outside 1..$maxCols');
    }
    if (rows < 1 || rows > maxRows) {
      throw ArgumentError('rows $rows outside 1..$maxRows');
    }
    var id = 0;
    return [
      for (var r = 0; r < rows; r++)
        [
          for (var c = 0; c < cols; c++) ++id,
        ],
    ];
  }

  static String gridId(int cols, int rows) => 'grid${cols}x$rows';

  /// Every shape the campaign can ask for, by id.
  static Map<String, List<List<int>>> get all => {
        for (final e in special.entries)
          e.key: e.value.map((row) => List<int>.from(row)).toList(),
        for (final size in gridSizes)
          gridId(size[0], size[1]): grid(size[0], size[1]),
      };

  static final RegExp _gridPattern = RegExp(r'^grid(\d+)x(\d+)$');

  static List<List<int>> byId(String id) {
    final named = special[id];
    if (named != null) {
      return named.map((row) => List<int>.from(row)).toList();
    }
    final match = _gridPattern.firstMatch(id);
    if (match != null) {
      return grid(int.parse(match.group(1)!), int.parse(match.group(2)!));
    }
    throw ArgumentError('Unknown shape id: $id');
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

  static int rowCount(List<List<int>> layout) => layout.length;

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
