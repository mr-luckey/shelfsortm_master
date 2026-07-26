/// A placeable good in Goods Puzzle triple-match mode.
/// Identity for matching is [type] (e.g. mug, cupcake) — same type matches.
class GameItem {
  final String id;
  final String type;
  final String color; // visual tint only

  const GameItem({
    required this.id,
    required this.type,
    required this.color,
  });

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'color': color,
      };

  factory GameItem.fromJson(Map<String, dynamic> json) => GameItem(
        id: json['id'] as String,
        type: json['type'] as String,
        color: json['color'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
