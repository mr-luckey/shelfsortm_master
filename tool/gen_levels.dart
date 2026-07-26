import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  for (var levelId = 1; levelId <= 50; levelId++) {
    final data = generate(levelId);
    final path =
        'assets/levels/level_${levelId.toString().padLeft(3, '0')}.json';
    File(path)
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    stdout.writeln(
      'Wrote $path items=${(data['initialPlacement'] as List).length} shelves=${data['shelfCount']}',
    );
  }
}

const themes = [
  (1, 5, 'kitchen', ['mug', 'cup', 'jar']),
  (6, 10, 'bakery', ['cupcake', 'box', 'macaron']),
  (11, 15, 'library', ['book', 'candle', 'globe']),
  (16, 20, 'garden', ['pot', 'can', 'seed']),
  (21, 25, 'toy', ['teddy', 'block', 'ball']),
  (26, 30, 'beauty', ['perfume', 'lipstick', 'cream']),
  (31, 35, 'gameden', ['controller', 'cartridge', 'headset']),
  (36, 40, 'market', ['can', 'sauce', 'snack']),
  (41, 45, 'decor', ['vase', 'frame', 'candle']),
  (46, 50, 'gift', ['ribbon', 'bag', 'ornament']),
];

const colors = [
  'red',
  'blue',
  'green',
  'yellow',
  'purple',
  'orange',
  'pink',
  'teal',
];

Map<String, dynamic> generate(int levelId) {
  final theme = themes.firstWhere((t) => levelId >= t.$1 && levelId <= t.$2);
  final difficulty = difficultyFor(levelId);
  final cfg = configFor(levelId);
  final rng = Random(levelId * 7919 + 17);
  final typeCount = cfg.$1;
  final buffers = cfg.$2;
  final shelfCount = typeCount + buffers;
  const slots = 3;

  final types = List<String>.from(theme.$4);
  while (types.length < typeCount) {
    types.add(theme.$4[types.length % theme.$4.length]);
  }
  final usedTypes = types.take(typeCount).toList();

  final items = <String>[];
  var counter = 0;
  for (final type in usedTypes) {
    final color = colors[rng.nextInt(colors.length)];
    for (var k = 0; k < 3; k++) {
      counter++;
      items.add('${type}_${color}_${counter.toString().padLeft(3, '0')}');
    }
  }

  final positions = <List<int>>[];
  for (var s = 0; s < typeCount; s++) {
    for (var slot = 0; slot < slots; slot++) {
      positions.add([s + 1, slot]);
    }
  }
  items.shuffle(rng);
  positions.shuffle(rng);

  final placements = <Map<String, dynamic>>[];
  for (var i = 0; i < items.length; i++) {
    placements.add({
      'itemId': items[i],
      'shelfId': positions[i][0],
      'slot': positions[i][1],
    });
  }

  final timeLimit = timeFor(difficulty, items.length);
  return {
    'levelId': levelId,
    'themeRoom': theme.$3,
    'difficulty': difficulty,
    'timeLimit': timeLimit,
    'shelfCount': shelfCount,
    'slotsPerShelf': slots,
    'bufferShelves': buffers,
    'initialPlacement': placements,
    'optimalMoves': items.length,
    'starThresholds': {
      '3star': (timeLimit * 0.45).round(),
      '2star': (timeLimit * 0.2).round(),
      '1star': 0,
    },
  };
}

String difficultyFor(int id) {
  if (id == 1 || id == 26) return 'rest';
  if (id % 25 == 0) return 'boss';
  if (id % 10 == 0) return 'tricky';
  if (id % 5 == 0) return 'hard';
  if (id <= 5) return 'easy';
  return 'standard';
}

(int, int) configFor(int id) {
  if (id <= 3) return (3, 2);
  if (id <= 15) return (4, 2);
  if (id <= 40) return (5, 2);
  return (6, 2);
}

int timeFor(String d, int items) {
  final base = (items * 4.5).round() + 50;
  switch (d) {
    case 'easy':
    case 'rest':
      return (base * 1.5).round().clamp(90, 280);
    case 'hard':
      return (base * 1.05).round().clamp(75, 220);
    case 'tricky':
      return base.clamp(70, 210);
    case 'boss':
      return (base * 0.95).round().clamp(100, 300);
    default:
      return (base * 1.2).round().clamp(85, 240);
  }
}
