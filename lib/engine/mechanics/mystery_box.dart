import '../match_engine.dart';
import '../../models/item.dart';
import 'level_mechanic.dart';
import 'mechanic_ids.dart';

class MysteryBox {
  final int shelfIndex;
  final int slotIndex;
  final GameItem hidden;
  final String trigger; // front_clear | shelf_complete | color_match | key
  bool opened;

  MysteryBox({
    required this.shelfIndex,
    required this.slotIndex,
    required this.hidden,
    this.trigger = 'front_clear',
    this.opened = false,
  });

  Map<String, dynamic> toJson() => {
        'shelfIndex': shelfIndex,
        'slotIndex': slotIndex,
        'hidden': hidden.toJson(),
        'trigger': trigger,
        'opened': opened,
      };

  factory MysteryBox.fromJson(Map<String, dynamic> json) => MysteryBox(
        shelfIndex: json['shelfIndex'] as int,
        slotIndex: json['slotIndex'] as int,
        hidden: GameItem.fromJson(json['hidden'] as Map<String, dynamic>),
        trigger: json['trigger'] as String? ?? 'front_clear',
        opened: json['opened'] as bool? ?? false,
      );
}

/// Concealed items revealed by a trigger (PRD §6A.10).
class MysteryBoxMechanic extends LevelMechanic {
  MatchEngine? _engine;
  final List<MysteryBox> boxes = [];

  @override
  String get id => MechanicIds.mysteryBoxes;

  @override
  void initialize(MatchEngine engine, Map<String, dynamic> config) {
    _engine = engine;
    boxes.clear();
    final raw = config['boxes'] as List? ?? [];
    for (final e in raw) {
      final m = e as Map<String, dynamic>;
      int shelfIndex = m['shelfIndex'] as int? ?? 0;
      int slotIndex = m['slotIndex'] as int? ?? 0;
      if (m['slot'] is String) {
        final parts = (m['slot'] as String).split(':');
        if (parts.length == 2) {
          final shelfId = int.tryParse(parts[0]) ?? 1;
          slotIndex = int.tryParse(parts[1]) ?? 0;
          shelfIndex =
              engine.shelves.indexWhere((s) => s.shelfId == shelfId);
          if (shelfIndex < 0) shelfIndex = 0;
        }
      }
      final hiddenId =
          m['itemId'] as String? ?? m['hidden'] as String? ?? 'mug_orange_001';
      final box = MysteryBox(
        shelfIndex: shelfIndex,
        slotIndex: slotIndex,
        hidden: GameItem.fromId(hiddenId).copyWith(isMystery: true),
        trigger: m['trigger'] as String? ?? 'front_clear',
      );
      boxes.add(box);
      _placeBox(box);
    }
  }

  void _placeBox(MysteryBox box) {
    final e = _engine;
    if (e == null || box.opened) return;
    if (box.shelfIndex < 0 || box.shelfIndex >= e.shelves.length) return;
    final shelf = e.shelves[box.shelfIndex];
    if (box.slotIndex < 0 || box.slotIndex >= shelf.slots.length) return;
    final slot = shelf.slots[box.slotIndex];
    final mysteryItem = box.hidden.copyWith(isMystery: true);
    if (slot.isEmpty) {
      e.shelves[box.shelfIndex] = shelf.withSlot(
        box.slotIndex,
        slot.copyWith(
          isMystery: true,
          mysteryTrigger: box.trigger,
          stack: [mysteryItem],
        ),
      );
    } else {
      e.shelves[box.shelfIndex] = shelf.withSlot(
        box.slotIndex,
        slot.copyWith(
          isMystery: true,
          mysteryTrigger: box.trigger,
          stack: [...slot.stack, mysteryItem],
        ),
      );
    }
  }

  void _open(MysteryBox box) {
    final e = _engine;
    if (e == null || box.opened) return;
    box.opened = true;
    if (box.shelfIndex < 0 || box.shelfIndex >= e.shelves.length) return;
    final shelf = e.shelves[box.shelfIndex];
    if (box.slotIndex < 0 || box.slotIndex >= shelf.slots.length) return;
    final slot = shelf.slots[box.slotIndex];
    final revealed = box.hidden.copyWith(isMystery: false);
    final newStack = slot.stack.map((item) {
      if (item.id == box.hidden.id || item.isMystery) return revealed;
      return item;
    }).toList();
    if (newStack.isEmpty) newStack.add(revealed);
    e.shelves[box.shelfIndex] = shelf.withSlot(
      box.slotIndex,
      slot.copyWith(
        isMystery: false,
        mysteryTrigger: null,
        stack: newStack,
      ),
    );
  }

  @override
  bool canInteract(BoardPos pos) {
    for (final box in boxes) {
      if (!box.opened &&
          box.shelfIndex == pos.shelfIndex &&
          box.slotIndex == pos.slotIndex) {
        final e = _engine;
        if (e == null) return false;
        final front = e.shelves[pos.shelfIndex].slots[pos.slotIndex].front;
        if (front != null && front.isMystery) return false;
      }
    }
    return true;
  }

  @override
  void onMoveCompleted(BoardPos from, BoardPos to) {
    for (final box in boxes) {
      if (box.opened) continue;
      if (box.trigger == 'front_clear' &&
          from.shelfIndex == box.shelfIndex &&
          from.slotIndex == box.slotIndex) {
        _open(box);
      }
    }
  }

  @override
  void onShelfCleared(int shelfIndex, String type) {
    for (final box in boxes) {
      if (box.opened) continue;
      if (box.trigger == 'shelf_complete' && box.shelfIndex == shelfIndex) {
        _open(box);
      }
      if (box.trigger == 'color_match') {
        _open(box);
      }
    }
  }

  @override
  String? get objectiveHint => 'Open mystery boxes to reveal hidden goods.';

  @override
  Map<String, dynamic> saveState() => {
        'boxes': boxes.map((e) => e.toJson()).toList(),
      };

  @override
  void loadState(Map<String, dynamic> json) {
    boxes
      ..clear()
      ..addAll(
        (json['boxes'] as List? ?? [])
            .map((e) => MysteryBox.fromJson(e as Map<String, dynamic>)),
      );
    for (final box in boxes) {
      if (!box.opened) _placeBox(box);
    }
  }
}
