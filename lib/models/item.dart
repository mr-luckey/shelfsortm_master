/// A placeable good in Goods Puzzle triple-match mode.
/// Identity for matching is [type] (e.g. mug, cupcake) — same type matches.
class GameItem {
  final String id;
  final String type;
  final String color; // visual tint only
  final bool isLocked;
  final int iceLayers;
  final bool isMystery;

  const GameItem({
    required this.id,
    required this.type,
    required this.color,
    this.isLocked = false,
    this.iceLayers = 0,
    this.isMystery = false,
  });

  bool get isFrozen => iceLayers > 0;
  bool get isInteractable => !isLocked && !isFrozen && !isMystery;

  /// id format: type_color_nn
  factory GameItem.fromId(String itemId) {
    final parts = itemId.split('_');
    if (parts.length < 2) {
      return GameItem(id: itemId, type: 'mug', color: 'orange');
    }
    return GameItem(
      id: itemId,
      type: parts[0],
      color: parts[1],
    );
  }

  GameItem copyWith({
    String? id,
    String? type,
    String? color,
    bool? isLocked,
    int? iceLayers,
    bool? isMystery,
  }) =>
      GameItem(
        id: id ?? this.id,
        type: type ?? this.type,
        color: color ?? this.color,
        isLocked: isLocked ?? this.isLocked,
        iceLayers: iceLayers ?? this.iceLayers,
        isMystery: isMystery ?? this.isMystery,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'color': color,
        if (isLocked) 'isLocked': true,
        if (iceLayers > 0) 'iceLayers': iceLayers,
        if (isMystery) 'isMystery': true,
      };

  factory GameItem.fromJson(Map<String, dynamic> json) => GameItem(
        id: json['id'] as String,
        type: json['type'] as String,
        color: json['color'] as String,
        isLocked: json['isLocked'] as bool? ?? false,
        iceLayers: json['iceLayers'] as int? ?? 0,
        isMystery: json['isMystery'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
