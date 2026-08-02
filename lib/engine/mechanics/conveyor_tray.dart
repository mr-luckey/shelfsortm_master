import '../match_engine.dart';
import 'level_mechanic.dart';
import 'mechanic_ids.dart';

/// Trays that ride past the cupboard on an endless belt.
///
/// The goods themselves live on dock [Shelf]s inside the engine, so a tray
/// keeps whatever it carries while it is off screen. This mechanic only owns
/// where the belt has scrolled to, which the belt widget advances every frame
/// through [advance] so movement stays smooth at 60 FPS.
class ConveyorTrayMechanic extends LevelMechanic {
  /// A level never runs more than this many trays.
  static const int maxTrays = 8;

  /// How quickly the belt returns to full speed after a pickup.
  static const double _accel = 3.0;

  int trayCount = 0;
  int slotsPerTray = 3;

  /// Trays per second at full speed.
  double speed = 0.28;

  /// Trays always ride right to left; -1 keeps that reading in the maths.
  static const int direction = -1;

  /// Engine indices of the tray shelves, pinned when the level starts so a
  /// booster shelf can never be mistaken for a tray.
  List<int> _trayShelves = const [];

  /// Trays visible in the belt window at once.
  double viewportTrays = 3.2;

  /// Belt speed while the player carries a good off a tray.
  double slowFactor = 0.5;

  /// Belt scroll in tray widths, always within `0 .. beltLength`.
  double offset = 0;

  /// Current fraction of [speed]; eases between 1 and [slowFactor].
  double speedFactor = 1;

  bool _carrying = false;
  bool reducedMotion = false;

  @override
  String get id => MechanicIds.conveyorTray;

  @override
  void initialize(MatchEngine engine, Map<String, dynamic> config) {
    trayCount = (config['trayCount'] as int? ?? engine.level.trayCount)
        .clamp(0, maxTrays);
    slotsPerTray = config['slotsPerTray'] as int? ?? engine.level.slotsPerShelf;
    speed = (config['speed'] as num?)?.toDouble() ?? 0.28;
    viewportTrays = (config['viewportTrays'] as num?)?.toDouble() ?? 3.2;
    slowFactor = ((config['slowFactor'] as num?)?.toDouble() ?? 0.5)
        .clamp(0.2, 1.0);
    offset = 0;
    speedFactor = 1;
    _carrying = false;
    _trayShelves = [
      for (var i = 0; i < engine.shelves.length; i++)
        if (engine.shelves[i].isDock) i,
    ].take(trayCount).toList(growable: false);
  }

  /// Engine indices of the tray shelves, in belt order.
  List<int> get trayShelfIndices => _trayShelves;

  bool get carrying => _carrying;

  /// Picking a good off a tray slows the belt down; placing it lets the belt
  /// build back up to full speed.
  void setCarrying(bool value) {
    if (_carrying == value) return;
    _carrying = value;
  }

  /// Length of the loop in tray widths. Always longer than the window plus one
  /// tray, so a tray only ever jumps back while it is fully out of sight.
  double get beltLength {
    final window = viewportTrays + 1.2;
    return trayCount > window ? trayCount.toDouble() : window;
  }

  /// Gap between trays along the loop, in tray widths.
  double get spacing => trayCount <= 0 ? 0 : beltLength / trayCount;

  /// Moves the belt on by [dt] seconds. Driven by the belt widget's ticker.
  void advance(double dt) {
    if (trayCount <= 0 || dt <= 0) return;
    final target = _carrying ? slowFactor : 1.0;
    if (speedFactor != target) {
      final step = _accel * dt;
      speedFactor = (target - speedFactor).abs() <= step
          ? target
          : speedFactor + (target > speedFactor ? step : -step);
    }
    if (reducedMotion) return;
    offset = (offset + speed * speedFactor * dt) % beltLength;
  }

  /// Where tray [ordinal] sits, in tray widths from the window's left edge.
  ///
  /// Trays travel toward the left. Positions run from -1 (just slid out past
  /// the left edge) up to `beltLength - 1`, so a tray only jumps back to the
  /// right once it is fully out of sight.
  double positionOf(int ordinal) {
    if (trayCount <= 0) return 0;
    final raw = ordinal * spacing + direction * offset + 1;
    final wrapped = raw % beltLength;
    return (wrapped < 0 ? wrapped + beltLength : wrapped) - 1;
  }

  @override
  String? get objectiveHint =>
      trayCount > 0 ? 'Trays keep rolling — grab goods as they pass.' : null;

  @override
  Map<String, dynamic> saveState() => {
        'offset': offset,
        'speedFactor': speedFactor,
        'carrying': _carrying,
      };

  @override
  void loadState(Map<String, dynamic> json) {
    offset = (json['offset'] as num?)?.toDouble() ?? 0;
    speedFactor = (json['speedFactor'] as num?)?.toDouble() ?? 1;
    _carrying = json['carrying'] as bool? ?? false;
    if (trayCount > 0) offset = offset % beltLength;
  }
}
