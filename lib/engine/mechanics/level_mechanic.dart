import '../match_engine.dart';

/// Abstract plugin for a single dynamic level mechanic (PRD §6A).
abstract class LevelMechanic {
  String get id;

  /// Called once when the level starts. [config] comes from level JSON.
  void initialize(MatchEngine engine, Map<String, dynamic> config);

  void start() {}
  void pause() {}
  void resume() {}
  void reset() {}

  /// Frame / timer tick for animated mechanics. [dt] in seconds.
  void tick(double dt) {}

  /// Return false to reject a proposed move.
  bool validateMove(BoardPos from, BoardPos to) => true;

  /// Called after a successful move (and match resolution).
  void onMoveCompleted(BoardPos from, BoardPos to) {}

  /// Called after a match clear on a shelf.
  void onShelfCleared(int shelfIndex, String type) {}

  /// Whether the front item at [pos] can be selected / moved.
  bool canInteract(BoardPos pos) => true;

  Map<String, dynamic> saveState() => {};
  void loadState(Map<String, dynamic> json) {}

  /// Short objective line for the HUD card.
  String? get objectiveHint => null;

  void dispose() {}
}
