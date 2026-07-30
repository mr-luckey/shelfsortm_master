import '../match_engine.dart';
import 'level_mechanic.dart';
import 'mechanic_ids.dart';
import 'locked_item.dart';
import 'mystery_box.dart';
import 'frozen_item.dart';

class ChainStep {
  final String action; // unlock_shelf | reveal_hidden | open_box | crack_ice
  final int? shelfIndex;
  final int? slotIndex;
  final String? target;
  bool executed;

  ChainStep({
    required this.action,
    this.shelfIndex,
    this.slotIndex,
    this.target,
    this.executed = false,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        if (shelfIndex != null) 'shelfIndex': shelfIndex,
        if (slotIndex != null) 'slotIndex': slotIndex,
        if (target != null) 'target': target,
        'executed': executed,
      };

  factory ChainStep.fromJson(Map<String, dynamic> json) => ChainStep(
        action: json['action'] as String,
        shelfIndex: json['shelfIndex'] as int?,
        slotIndex: json['slotIndex'] as int?,
        target: json['target'] as String?,
        executed: json['executed'] as bool? ?? false,
      );
}

class ChainEvent {
  final String trigger; // type_clear | shelf_complete | color_group
  final String? triggerValue;
  final List<ChainStep> steps;
  bool fired;

  ChainEvent({
    required this.trigger,
    this.triggerValue,
    required this.steps,
    this.fired = false,
  });

  Map<String, dynamic> toJson() => {
        'trigger': trigger,
        if (triggerValue != null) 'triggerValue': triggerValue,
        'steps': steps.map((e) => e.toJson()).toList(),
        'fired': fired,
      };

  factory ChainEvent.fromJson(Map<String, dynamic> json) => ChainEvent(
        trigger: json['trigger'] as String,
        triggerValue: json['triggerValue'] as String?,
        steps: (json['steps'] as List? ?? [])
            .map((e) => ChainStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        fired: json['fired'] as bool? ?? false,
      );
}

/// One correct action triggers a sequence of reveals (PRD §6A.14).
class ChainReleaseMechanic extends LevelMechanic {
  MatchEngine? _engine;
  final List<ChainEvent> events = [];
  LockedItemMechanic? lockedRef;
  MysteryBoxMechanic? mysteryRef;
  FrozenItemMechanic? frozenRef;

  /// Last chain feedback message for UI.
  String? lastChainMessage;

  @override
  String get id => MechanicIds.chainRelease;

  @override
  void initialize(MatchEngine engine, Map<String, dynamic> config) {
    _engine = engine;
    events.clear();
    lastChainMessage = null;
    final raw = config['events'] as List? ?? [];
    for (final e in raw) {
      events.add(ChainEvent.fromJson(e as Map<String, dynamic>));
    }
  }

  void bindPeers({
    LockedItemMechanic? locked,
    MysteryBoxMechanic? mystery,
    FrozenItemMechanic? frozen,
  }) {
    lockedRef = locked;
    mysteryRef = mystery;
    frozenRef = frozen;
  }

  @override
  void onShelfCleared(int shelfIndex, String type) {
    for (final event in events) {
      if (event.fired) continue;
      final match = switch (event.trigger) {
        'type_clear' =>
          event.triggerValue == null || event.triggerValue == type,
        'shelf_complete' => true,
        'color_group' => true,
        _ => false,
      };
      if (match) _fire(event);
    }
  }

  void _fire(ChainEvent event) {
    event.fired = true;
    lastChainMessage = 'Chain Release!';
    for (final step in event.steps) {
      if (step.executed) continue;
      step.executed = true;
      switch (step.action) {
        case 'unlock_shelf':
        case 'unlock_item':
          if (lockedRef != null) {
            for (final lock in lockedRef!.locks) {
              if (step.shelfIndex != null &&
                  lock.shelfIndex == step.shelfIndex &&
                  (step.slotIndex == null ||
                      lock.slotIndex == step.slotIndex)) {
                lock.unlocked = false; // force re-eval
                // Mark unlocked via public path: set unlocked + clear flags
                lock.unlocked = true;
                final e = _engine;
                if (e != null &&
                    lock.shelfIndex >= 0 &&
                    lock.shelfIndex < e.shelves.length) {
                  final shelf = e.shelves[lock.shelfIndex];
                  if (lock.slotIndex >= 0 &&
                      lock.slotIndex < shelf.slots.length) {
                    final slot = shelf.slots[lock.slotIndex];
                    final front = slot.front;
                    e.shelves[lock.shelfIndex] = shelf.withSlot(
                      lock.slotIndex,
                      slot.copyWith(
                        isLocked: false,
                        stack: front == null
                            ? slot.stack
                            : [
                                front.copyWith(isLocked: false),
                                ...slot.stack.skip(1),
                              ],
                      ),
                    );
                  }
                }
              }
            }
          }
        case 'open_box':
          if (mysteryRef != null) {
            for (final box in mysteryRef!.boxes) {
              if (step.shelfIndex != null &&
                  box.shelfIndex == step.shelfIndex) {
                // Trigger via shelf_complete style
                box.opened = false;
              }
            }
            mysteryRef!.onShelfCleared(step.shelfIndex ?? 0, '');
          }
        case 'crack_ice':
          if (frozenRef != null) {
            for (final f in frozenRef!.frozen) {
              if (step.shelfIndex == null ||
                  f.shelfIndex == step.shelfIndex) {
                if (f.layers > 0) f.layers = 0;
              }
            }
            frozenRef!.onShelfCleared(step.shelfIndex ?? 0, '');
          }
        case 'reveal_hidden':
          // Depth already slides forward on clear — cinematic message only
          lastChainMessage = 'Hidden items revealed!';
      }
    }
  }

  @override
  String? get objectiveHint =>
      'Complete groups to trigger chain releases.';

  @override
  Map<String, dynamic> saveState() => {
        'events': events.map((e) => e.toJson()).toList(),
        if (lastChainMessage != null) 'lastChainMessage': lastChainMessage,
      };

  @override
  void loadState(Map<String, dynamic> json) {
    events
      ..clear()
      ..addAll(
        (json['events'] as List? ?? [])
            .map((e) => ChainEvent.fromJson(e as Map<String, dynamic>)),
      );
    lastChainMessage = json['lastChainMessage'] as String?;
  }
}
