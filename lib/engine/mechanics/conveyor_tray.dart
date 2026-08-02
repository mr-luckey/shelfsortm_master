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

  MatchEngine? _engine;

  int trayCount = 0;
  int slotsPerTray = 3;

  /// Trays per second at full speed.
  double speed = 0.28;

  /// +1 rides to the right, -1 to the left.
  int direction = 1;

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
    _engine = engine;
    trayCount = (config['trayCount'] as int? ?? engine.level.trayCount)
        .clamp(0, maxTrays);
    slotsPerTray = config['slotsPerTray'] as int? ?? engine.level.slotsPerShelf;
    speed = (config['speed'] as num?)?.toDouble() ?? 0.28;
    direction = (config['direction'] as int? ?? 1) >= 0 ? 1 : -1;
    viewportTrays = (config['viewportTrays'] as num?)?.toDouble() ?? 3.2;
    slowFactor = ((config['slowFactor'] as num?)?.toDouble() ?? 0.5)
        .clamp(0.2, 1.0);
    offset = 0;
    speedFactor = 1;
    _carrying = false;
  }

  /// Engine indices of the tray shelves, in belt order.
  List<int> get trayShelfIndices {
    final e = _engine;
    if (e == null) return const [];
    return [
      for (var i = 0; i < e.shelves.length; i++)
        if (e.shelves[i].isDock) i,
    ];
  }

  bool get carrying => _carrying;

  /// Picking a good off a tray slows the belt down; placing it lets the belt
  /// build back up to full speed.
  void setCarrying(bool value) {
    if (_carrying == value) return;
    _carrying = value;
  }

  /// Length of the loop in tray widths. Always longer than the window so a
  /// tray never jumps position while the player can see it.
  double get beltLength {
    final window = viewportTrays + 1;
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
  /// A tray that rides out of view comes back around with its goods intact.
  double positionOf(int ordinal) {
    if (trayCount <= 0) return 0;
    final raw = direction >= 0
        ? ordinal * spacing + offset
        : ordinal * spacing - offset;
    final wrapped = raw % beltLength;
    return wrapped < 0 ? wrapped + beltLength : wrapped;
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
