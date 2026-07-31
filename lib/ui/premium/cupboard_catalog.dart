/// Clean FULL cupboard skins only (no cropped fragments).
/// Prefer tall boards: more rows, ≤4 columns.
class CupboardSkin {
  final String id;
  final String assetPath;
  final int rows;
  final int cols;
  final double insetLeft;
  final double insetTop;
  final double insetRight;
  final double insetBottom;

  const CupboardSkin({
    required this.id,
    required this.assetPath,
    required this.rows,
    required this.cols,
    this.insetLeft = 0.07,
    this.insetTop = 0.055,
    this.insetRight = 0.07,
    this.insetBottom = 0.13,
  });

  int get capacity => rows * cols;
}

abstract final class CupboardCatalog {
  static const root = 'assets/images/premium/cupboards';

  static const List<CupboardSkin> all = [
    CupboardSkin(
      id: '2x2',
      assetPath: '$root/cupboard_2x2.png',
      rows: 2,
      cols: 2,
      insetLeft: 0.08,
      insetRight: 0.08,
      insetTop: 0.06,
      insetBottom: 0.18,
    ),
    CupboardSkin(
      id: '3x2',
      assetPath: '$root/cupboard_3x2.png',
      rows: 3,
      cols: 2,
      insetLeft: 0.10,
      insetRight: 0.10,
      insetTop: 0.05,
      insetBottom: 0.17,
    ),
    CupboardSkin(
      id: '4x2',
      assetPath: '$root/cupboard_4x2.png',
      rows: 4,
      cols: 2,
      insetLeft: 0.10,
      insetRight: 0.10,
      insetTop: 0.045,
      insetBottom: 0.15,
    ),
    CupboardSkin(
      id: '2x3',
      assetPath: '$root/cupboard_2x3.png',
      rows: 2,
      cols: 3,
      insetLeft: 0.06,
      insetRight: 0.06,
      insetTop: 0.07,
      insetBottom: 0.16,
    ),
    CupboardSkin(
      id: '4x3',
      assetPath: '$root/cupboard_4x3.png',
      rows: 4,
      cols: 3,
      insetLeft: 0.08,
      insetRight: 0.08,
      insetTop: 0.05,
      insetBottom: 0.16,
    ),
    CupboardSkin(
      id: '5x3',
      assetPath: '$root/cupboard_5x3.png',
      rows: 5,
      cols: 3,
      insetBottom: 0.11,
    ),
    CupboardSkin(
      id: '6x4',
      assetPath: '$root/cupboard_6x4.png',
      rows: 6,
      cols: 4,
      insetLeft: 0.065,
      insetRight: 0.065,
      insetTop: 0.04,
      insetBottom: 0.105,
    ),
    CupboardSkin(
      id: '7x4',
      assetPath: '$root/cupboard_7x4.png',
      rows: 7,
      cols: 4,
      insetBottom: 0.10,
    ),
    CupboardSkin(
      id: '8x4',
      assetPath: '$root/cupboard_8x4.png',
      rows: 8,
      cols: 4,
      insetBottom: 0.10,
    ),
  ];

  /// Tall cupboard sized to fit [shelfCount] shelves.
  static CupboardSkin forShelfCount(int shelfCount) {
    final n = shelfCount.clamp(1, 32);
    if (n <= 4) return _id('2x2');
    if (n <= 6) return _id('3x2');
    if (n <= 8) return _id('4x2');
    if (n <= 12) return _id('4x3');
    if (n <= 15) return _id('5x3');
    if (n <= 24) return _id('6x4');
    if (n <= 28) return _id('7x4');
    return _id('8x4');
  }

  static List<List<int>> packLayout({
    required List<int> shelfIds,
    required CupboardSkin skin,
  }) {
    final grid = List.generate(
      skin.rows,
      (_) => List<int>.filled(skin.cols, 0),
    );
    var i = 0;
    for (var r = 0; r < skin.rows && i < shelfIds.length; r++) {
      for (var c = 0; c < skin.cols && i < shelfIds.length; c++) {
        grid[r][c] = shelfIds[i++];
      }
    }
    return grid;
  }

  static CupboardSkin _id(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}
