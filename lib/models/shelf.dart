import 'item.dart';

class ShelfSlot {
  final GameItem? item;

  const ShelfSlot({this.item});

  bool get isEmpty => item == null;

  ShelfSlot copyWith({GameItem? item, bool clear = false}) =>
      ShelfSlot(item: clear ? null : (item ?? this.item));

  Map<String, dynamic> toJson() => {'item': item?.toJson()};

  factory ShelfSlot.fromJson(Map<String, dynamic> json) => ShelfSlot(
        item: json['item'] != null
            ? GameItem.fromJson(json['item'] as Map<String, dynamic>)
            : null,
      );
}

class Shelf {
  final int shelfId;
  final int slotCount;
  final List<ShelfSlot> slots;
  final bool isTemporary;
  final bool isDock;

  const Shelf({
    required this.shelfId,
    required this.slotCount,
    required this.slots,
    this.isTemporary = false,
    this.isDock = false,
  });

  bool get isFull => slots.every((s) => !s.isEmpty);

  bool get isEmpty => slots.every((s) => s.isEmpty);

  int get occupiedCount => slots.where((s) => !s.isEmpty).length;

  int get firstEmptyIndex => slots.indexWhere((s) => s.isEmpty);

  Map<String, int> typeCounts() {
    final map = <String, int>{};
    for (final s in slots) {
      final item = s.item;
      if (item == null) continue;
      map[item.type] = (map[item.type] ?? 0) + 1;
    }
    return map;
  }

  String? matchableType() {
    for (final e in typeCounts().entries) {
      if (e.value >= 3) return e.key;
    }
    return null;
  }

  Shelf copyWith({
    int? shelfId,
    int? slotCount,
    List<ShelfSlot>? slots,
    bool? isTemporary,
    bool? isDock,
  }) =>
      Shelf(
        shelfId: shelfId ?? this.shelfId,
        slotCount: slotCount ?? this.slotCount,
        slots: slots ?? this.slots,
        isTemporary: isTemporary ?? this.isTemporary,
        isDock: isDock ?? this.isDock,
      );

  Shelf withSlot(int index, ShelfSlot slot) {
    final next = List<ShelfSlot>.from(slots);
    next[index] = slot;
    return copyWith(slots: next);
  }

  Map<String, dynamic> toJson() => {
        'shelfId': shelfId,
        'slotCount': slotCount,
        'slots': slots.map((s) => s.toJson()).toList(),
        'isTemporary': isTemporary,
        'isDock': isDock,
      };

  factory Shelf.fromJson(Map<String, dynamic> json) => Shelf(
        shelfId: json['shelfId'] as int,
        slotCount: json['slotCount'] as int,
        slots: (json['slots'] as List)
            .map((e) => ShelfSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
        isTemporary: json['isTemporary'] as bool? ?? false,
        isDock: json['isDock'] as bool? ?? false,
      );
}
