import 'package:equatable/equatable.dart';

import '../engine/match_engine.dart';
import '../models/level_data.dart';

enum BoosterKind { undo, freeze, shuffle, magnet, extraShelf }

sealed class GameEvent extends Equatable {
  const GameEvent();
  @override
  List<Object?> get props => [];
}

class GameStarted extends GameEvent {
  final LevelData level;
  final Map<String, dynamic>? midSave;
  const GameStarted(this.level, {this.midSave});
  @override
  List<Object?> get props => [level.levelId];
}

class ItemTapped extends GameEvent {
  final BoardPos pos;
  const ItemTapped(this.pos);
  @override
  List<Object?> get props => [pos];
}

class ItemMoved extends GameEvent {
  final BoardPos from;
  final BoardPos to;
  const ItemMoved({required this.from, required this.to});
  @override
  List<Object?> get props => [from, to];
}


class TimerTicked extends GameEvent {
  const TimerTicked();
}

class BoosterPressed extends GameEvent {
  final BoosterKind kind;
  const BoosterPressed(this.kind);
  @override
  List<Object?> get props => [kind];
}

class PauseToggled extends GameEvent {
  final bool paused;
  const PauseToggled(this.paused);
  @override
  List<Object?> get props => [paused];
}

class GameRestarted extends GameEvent {
  const GameRestarted();
}

class BannerCleared extends GameEvent {
  const BannerCleared();
}
