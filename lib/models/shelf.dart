import 'item.dart';

/// One column on a shelf. Index 0 = FRONT (playable). Rest = hidden behind.
class ShelfSlot {
  final List<GameItem> stack;
  final bool isLocked;
  final String? lockCondition;
  final int freezeLayers;
  final bool isMystery;
  final String? mysteryTrigger;
  /// Whether this slot is currently accessible (sliding shelf / divider).
  final bool accessible;

  const ShelfSlot({
    this.stack = const [],
    this.isLocked = false,
    this.lockCondition,
    this.freezeLayers = 0,
    this.isMystery = false,
    this.mysteryTrigger,
    this.accessible = true,
  });

  factory ShelfSlot.front(GameItem item) => ShelfSlot(stack: [item]);

  bool get isEmpty => stack.isEmpty;

  GameItem? get front => stack.isEmpty ? null : stack.first;

  GameItem? get peekBehind => stack.length > 1 ? stack[1] : null;

  int get depth => stack.length;

  /// Legacy single-item accessor used by older UI bits.
  GameItem? get item => front;

  bool get frontBlocked {
    final f = front;
    if (f == null) return false;
    if (!accessible) return true;
    if (isLocked || f.isLocked) return true;
    if (freezeLayers > 0 || f.isFrozen) return true;
    if (isMystery || f.isMystery) return true;
    return false;
  }

  ShelfSlot copyWith({
    List<GameItem>? stack,
    bool? isLocked,
    String? lockCondition,
    int? freezeLayers,
    bool? isMystery,
    String? mysteryTrigger,
    bool? accessible,
  }) =>
      ShelfSlot(
        stack: stack ?? this.stack,
        isLocked: isLocked ?? this.isLocked,
        lockCondition: lockCondition ?? this.lockCondition,
        freezeLayers: freezeLayers ?? this.freezeLayers,
        isMystery: isMystery ?? this.isMystery,
        mysteryTrigger: mysteryTrigger ?? this.mysteryTrigger,
        accessible: accessible ?? this.accessible,
      );

  ShelfSlot withFrontRemoved() {
    if (stack.isEmpty) return this;
    return copyWith(stack: List<GameItem>.from(stack.skip(1)));
  }

  ShelfSlot withFront(GameItem item) =>
      copyWith(stack: [item, ...stack]);

  ShelfSlot replacingFront(GameItem? item) {
    final rest = stack.length <= 1 ? <GameItem>[] : stack.sublist(1);
    if (item == null) return copyWith(stack: rest);
    return copyWith(stack: [item, ...rest]);
  }

  Map<String, dynamic> toJson() => {
        'stack': stack.map((e) => e.toJson()).toList(),
        if (isLocked) 'isLocked': true,
        if (lockCondition != null) 'lockCondition': lockCondition,
        if (freezeLayers > 0) 'freezeLayers': freezeLayers,
        if (isMystery) 'isMystery': true,
        if (mysteryTrigger != null) 'mysteryTrigger': mysteryTrigger,
        if (!accessible) 'accessible': false,
      };

  factory ShelfSlot.fromJson(Map<String, dynamic> json) {
    List<GameItem> list = const [];
    if (json['stack'] is List) {
      list = (json['stack'] as List)
          .map((e) => GameItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['item'] != null) {
      list = [GameItem.fromJson(json['item'] as Map<String, dynamic>)];
    }
    return ShelfSlot(
      stack: list,
      isLocked: json['isLocked'] as bool? ?? false,
      lockCondition: json['lockCondition'] as String?,
      freezeLayers: json['freezeLayers'] as int? ?? 0,
      isMystery: json['isMystery'] as bool? ?? false,
      mysteryTrigger: json['mysteryTrigger'] as String?,
      accessible: json['accessible'] as bool? ?? true,
    );
  }
}

class Shelf {
  final int shelfId;
  final int slotCount;
  final List<ShelfSlot> slots;
  final bool isTemporary;
  final bool isDock;
  /// Horizontal slide offset in slots (-n .. +n). 0 = home.
  final int slideOffset;
  /// Divider position: splits slots into left/right groups at this index.
  final int? dividerIndex;

  const Shelf({
    required this.shelfId,
    required this.slotCount,
    required this.slots,
    this.isTemporary = false,
    this.isDock = false,
    this.slideOffset = 0,
    this.dividerIndex,
  });

  bool get isFull => slots.every((s) => !s.isEmpty);

  bool get isEmpty => slots.every((s) => s.isEmpty);

  int get occupiedCount =>
      slots.fold<int>(0, (n, s) => n + s.stack.length);

  int get frontOccupied => slots.where((s) => !s.isEmpty).length;

  int get emptyFrontCount =>
      slots.where((s) => s.isEmpty && s.accessible).length;

  int get firstEmptyIndex =>
      slots.indexWhere((s) => s.isEmpty && s.accessible);

  /// Front-row match: all 3 fronts present, same type, and interactable.
  String? matchableType() {
    if (slots.length < 3) return null;
    if (slots.any((s) => s.isEmpty || s.frontBlocked)) return null;
    final t = slots[0].front!.type;
    if (slots.every((s) => s.front!.type == t)) return t;
    return null;
  }

  Shelf copyWith({
    int? shelfId,
    int? slotCount,
    List<ShelfSlot>? slots,
    bool? isTemporary,
    bool? isDock,
    int? slideOffset,
    int? dividerIndex,
    bool clearDivider = false,
  }) =>
      Shelf(
        shelfId: shelfId ?? this.shelfId,
        slotCount: slotCount ?? this.slotCount,
        slots: slots ?? this.slots,
        isTemporary: isTemporary ?? this.isTemporary,
        isDock: isDock ?? this.isDock,
        slideOffset: slideOffset ?? this.slideOffset,
        dividerIndex:
            clearDivider ? null : (dividerIndex ?? this.dividerIndex),
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
        if (slideOffset != 0) 'slideOffset': slideOffset,
        if (dividerIndex != null) 'dividerIndex': dividerIndex,
      };

  factory Shelf.fromJson(Map<String, dynamic> json) => Shelf(
        shelfId: json['shelfId'] as int,
        slotCount: json['slotCount'] as int,
        slots: (json['slots'] as List)
            .map((e) => ShelfSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
        isTemporary: json['isTemporary'] as bool? ?? false,
        isDock: json['isDock'] as bool? ?? false,
        slideOffset: json['slideOffset'] as int? ?? 0,
        dividerIndex: json['dividerIndex'] as int?,
      );
}
