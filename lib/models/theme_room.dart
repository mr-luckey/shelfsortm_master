class ThemeRoom {
  final String id;
  final String name;
  final String emoji;
  final List<String> itemTypes;
  final String shelfStyle;
  final int startLevel;
  final int endLevel;

  const ThemeRoom({
    required this.id,
    required this.name,
    required this.emoji,
    required this.itemTypes,
    required this.shelfStyle,
    required this.startLevel,
    required this.endLevel,
  });

  static const List<ThemeRoom> all = [
    ThemeRoom(
      id: 'kitchen',
      name: 'Cozy Kitchen',
      emoji: '☕',
      itemTypes: ['mug', 'cup', 'jar'],
      shelfStyle: 'oak',
      startLevel: 1,
      endLevel: 5,
    ),
    ThemeRoom(
      id: 'bakery',
      name: 'Sweet Bakery',
      emoji: '🍰',
      itemTypes: ['cupcake', 'box', 'macaron'],
      shelfStyle: 'marble',
      startLevel: 6,
      endLevel: 10,
    ),
    ThemeRoom(
      id: 'library',
      name: 'Vintage Library',
      emoji: '📚',
      itemTypes: ['book', 'candle', 'globe'],
      shelfStyle: 'walnut',
      startLevel: 11,
      endLevel: 15,
    ),
    ThemeRoom(
      id: 'garden',
      name: 'Garden Corner',
      emoji: '🌿',
      itemTypes: ['pot', 'can', 'seed'],
      shelfStyle: 'bamboo',
      startLevel: 16,
      endLevel: 20,
    ),
    ThemeRoom(
      id: 'toy',
      name: 'Toy Chest',
      emoji: '🧸',
      itemTypes: ['teddy', 'block', 'ball'],
      shelfStyle: 'plastic',
      startLevel: 21,
      endLevel: 25,
    ),
    ThemeRoom(
      id: 'beauty',
      name: 'Beauty Boutique',
      emoji: '💄',
      itemTypes: ['perfume', 'lipstick', 'cream'],
      shelfStyle: 'acrylic',
      startLevel: 26,
      endLevel: 30,
    ),
    ThemeRoom(
      id: 'gameden',
      name: 'Game Den',
      emoji: '🎮',
      itemTypes: ['controller', 'cartridge', 'headset'],
      shelfStyle: 'metal',
      startLevel: 31,
      endLevel: 35,
    ),
    ThemeRoom(
      id: 'market',
      name: 'Food Market',
      emoji: '🍕',
      itemTypes: ['can', 'sauce', 'snack'],
      shelfStyle: 'stall',
      startLevel: 36,
      endLevel: 40,
    ),
    ThemeRoom(
      id: 'decor',
      name: 'Home Décor',
      emoji: '🏡',
      itemTypes: ['vase', 'frame', 'candle'],
      shelfStyle: 'minimal',
      startLevel: 41,
      endLevel: 45,
    ),
    ThemeRoom(
      id: 'gift',
      name: 'Gift Wrapping',
      emoji: '🎁',
      itemTypes: ['ribbon', 'bag', 'ornament'],
      shelfStyle: 'festive',
      startLevel: 46,
      endLevel: 50,
    ),
  ];

  static ThemeRoom forLevel(int levelId) {
    return all.firstWhere(
      (t) => levelId >= t.startLevel && levelId <= t.endLevel,
      orElse: () => all.first,
    );
  }

  static ThemeRoom byId(String id) {
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }
}

enum LevelDifficulty { easy, standard, hard, tricky, boss, rest }

extension LevelDifficultyX on LevelDifficulty {
  String get label {
    switch (this) {
      case LevelDifficulty.easy:
        return 'Easy';
      case LevelDifficulty.standard:
        return 'Normal';
      case LevelDifficulty.hard:
        return 'Hard';
      case LevelDifficulty.tricky:
        return 'Tricky';
      case LevelDifficulty.boss:
        return 'Boss';
      case LevelDifficulty.rest:
        return 'Rest';
    }
  }

  static LevelDifficulty forLevel(int levelId) {
    if (levelId == 1 || levelId == 26) return LevelDifficulty.rest;
    if (levelId % 25 == 0) return LevelDifficulty.boss;
    if (levelId % 10 == 0) return LevelDifficulty.tricky;
    if (levelId % 5 == 0) return LevelDifficulty.hard;
    if (levelId <= 5) return LevelDifficulty.easy;
    return LevelDifficulty.standard;
  }
}
