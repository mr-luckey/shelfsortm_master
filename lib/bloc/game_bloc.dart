import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../engine/match_engine.dart';
import '../engine/mechanics/moving_bottom_tray.dart';
import '../engine/mechanics/rotating_tray.dart';
import '../engine/mechanics/sliding_shelf.dart';
import '../models/item.dart';
import '../models/shelf.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  MatchEngine? _engine;
  Timer? _clock;
  Timer? _mechClock;
  Timer? _freezeTimer;
  Timer? _bannerTimer;
  Timer? _shelfAnimTimer;

  GameBloc() : super(const GameState()) {
    on<GameStarted>(_onStarted);
    on<ItemMoved>(_onMoved);
    on<ItemTapped>(_onTapped);
    on<TimerTicked>(_onTick);
    on<MechanicTick>(_onMechTick);
    on<BoosterPressed>(_onBooster);
    on<PauseToggled>(_onPause);
    on<GameRestarted>(_onRestart);
    on<BannerCleared>(_onBannerCleared);
    on<ShelfWaveOpened>(_onShelfWaveOpened);
    on<ContinueAfterAd>(_onContinueAfterAd);
  }

  MatchEngine? get engine => _engine;

  Map<String, dynamic> _visuals(MatchEngine e) {
    final out = <String, dynamic>{};
    final tray = e.mechanics.ofType<MovingBottomTrayMechanic>();
    if (tray != null) {
      out['trayPosition'] = tray.position;
      out['trayDirection'] = tray.direction;
    }
    final rot = e.mechanics.ofType<RotatingTrayMechanic>();
    if (rot != null) {
      out['trayAngle'] = rot.angle;
      out['rotationSteps'] = rot.rotationSteps;
    }
    final slide = e.mechanics.ofType<SlidingShelfMechanic>();
    if (slide != null) {
      out['slideState'] = slide.slideState;
    }
    return out;
  }

  GameState _snap({
    String? banner,
    int clearingShelf = -1,
    int openingShelf = -1,
    bool clearBanner = false,
  }) {
    final e = _engine!;
    final hints = e.mechanics.objectiveHints;
    String? comboBanner = banner;
    if (banner == null && e.combo >= 7) {
      comboBanner = 'UNSTOPPABLE!';
    } else if (banner == null && e.combo >= 5) {
      comboBanner = 'On Fire!';
    } else if (banner == null && e.combo >= 3) {
      comboBanner = 'Combo x${e.combo}!';
    }
    return GameState(
      level: e.level,
      shelves: e.shelves
          .map((s) => s.copyWith(slots: List<ShelfSlot>.from(s.slots)))
          .toList(),
      belt: List<GameItem?>.from(e.belt),
      reserveCount: 0,
      moves: e.moves,
      matches: e.matches,
      combo: e.combo,
      timeLeft: e.timeLeft,
      frozen: e.frozen,
      status: e.status,
      lastClear: e.lastClear,
      banner: clearBanner ? null : comboBanner,
      clearingShelf: clearingShelf,
      openingShelf: openingShelf,
      inputLocked: e.inputLocked,
      finishedShelves: e.waves.finishedShelfIndices,
      ready: true,
      selected: e.selected,
      activeMechanics: e.level.mechanics,
      objectiveHint: hints.isEmpty ? null : hints.first,
      maxCombo: e.maxCombo,
      mechanicVisual: _visuals(e),
      nextLayers: e.nextLayers,
    );
  }

  void _onStarted(GameStarted event, Emitter<GameState> emit) {
    _clock?.cancel();
    _mechClock?.cancel();
    _freezeTimer?.cancel();
    _bannerTimer?.cancel();
    _shelfAnimTimer?.cancel();
    _engine = MatchEngine(level: event.level);
    if (event.midSave != null) {
      try {
        _engine!.loadSaveJson(event.midSave!);
      } catch (_) {}
    }
    emit(_snap());
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const TimerTicked());
    });
    // ~20 FPS mechanic tick for smooth tray/conveyor
    _mechClock = Timer.periodic(const Duration(milliseconds: 50), (_) {
      add(const MechanicTick(0.05));
    });
  }

  void _onTapped(ItemTapped event, Emitter<GameState> emit) {
    final e = _engine;
    if (e == null || e.status != GameStatus.playing) return;
    final before = e.matches;
    final beforeCombo = e.combo;
    final ok = e.tap(event.pos);
    if (!ok) {
      emit(_snap());
      return;
    }
    var clearing = -1;
    String? banner;
    if (e.matches > before && e.lastClear != null) {
      clearing = e.lastClear!.shelfIndex;
      if (e.combo >= 7) {
        banner = 'UNSTOPPABLE!';
      } else if (e.combo >= 5) {
        banner = 'On Fire!';
      } else if (e.combo >= 3) {
        banner = 'Combo x${e.combo}!';
      } else {
        banner = 'Cleared!';
      }
      _flashBanner();
    } else if (e.combo > beforeCombo && e.combo >= 3) {
      banner = 'Combo x${e.combo}!';
      _flashBanner();
    }
    emit(_snap(banner: banner, clearingShelf: clearing));
    if (clearing >= 0) _scheduleShelfWave(clearing);
  }

  void _onMoved(ItemMoved event, Emitter<GameState> emit) {
    final e = _engine;
    if (e == null || e.status != GameStatus.playing) return;
    final before = e.matches;
    e.selected = null;
    final ok = e.move(event.from, event.to);
    if (!ok) {
      emit(_snap(banner: 'Need an empty slot'));
      _flashBanner();
      return;
    }
    var clearing = -1;
    String? banner;
    if (e.matches > before && e.lastClear != null) {
      clearing = e.lastClear!.shelfIndex;
      if (e.combo >= 7) {
        banner = 'UNSTOPPABLE!';
      } else if (e.combo >= 5) {
        banner = 'On Fire!';
      } else if (e.combo >= 3) {
        banner = 'Combo x${e.combo}!';
      } else {
        banner = 'Cleared!';
      }
      _flashBanner();
    }
    emit(_snap(banner: banner, clearingShelf: clearing));
    if (clearing >= 0) _scheduleShelfWave(clearing);
  }

  void _scheduleShelfWave(int shelfIndex) {
    _shelfAnimTimer?.cancel();
    _shelfAnimTimer = Timer(const Duration(milliseconds: 520), () {
      if (isClosed || _engine == null) return;
      _engine!.finishShelfClose(shelfIndex);
      if (_engine!.waves.hasPendingWave(shelfIndex)) {
        add(ShelfWaveOpened(shelfIndex));
      } else {
        _engine!.unlockInput();
        if (!isClosed) add(const BannerCleared());
      }
    });
  }

  void _onShelfWaveOpened(ShelfWaveOpened event, Emitter<GameState> emit) {
    final e = _engine;
    if (e == null) return;
    e.openNextWave(event.shelfIndex);
    emit(_snap(openingShelf: event.shelfIndex, clearingShelf: -1));
    _shelfAnimTimer?.cancel();
    _shelfAnimTimer = Timer(const Duration(milliseconds: 480), () {
      if (!isClosed) add(const BannerCleared());
    });
  }

  void _onTick(TimerTicked event, Emitter<GameState> emit) {
    final e = _engine;
    if (e == null) return;
    if (e.status != GameStatus.playing) return;
    e.tickSecond();
    emit(_snap(
      banner: state.banner,
      clearingShelf: state.clearingShelf,
      openingShelf: state.openingShelf,
    ));
  }

  void _onMechTick(MechanicTick event, Emitter<GameState> emit) {
    final e = _engine;
    if (e == null || e.status != GameStatus.playing) return;
    if (e.mechanics.mechanics.isEmpty) return;
    e.tickMechanics(event.dt);
    // Only re-emit if animated visuals changed
    final v = _visuals(e);
    if (v.isEmpty) return;
    emit(_snap(
      banner: state.banner,
      clearingShelf: state.clearingShelf,
      openingShelf: state.openingShelf,
    ));
  }

  void _onBooster(BoosterPressed event, Emitter<GameState> emit) {
    final e = _engine;
    if (e == null) return;
    switch (event.kind) {
      case BoosterKind.undo:
        e.undo();
      case BoosterKind.freeze:
        e.setFrozen(true);
        _freezeTimer?.cancel();
        _freezeTimer = Timer(const Duration(seconds: 10), () {
          _engine?.setFrozen(false);
          if (!isClosed) add(const BannerCleared());
        });
      case BoosterKind.shuffle:
        e.shuffleBoard();
      case BoosterKind.magnet:
        if (e.selected != null && e.itemAt(e.selected!) != null) {
          e.hammerRemove(e.selected!);
        } else {
          final t = e.dominantType();
          if (t != null) {
            outer:
            for (var si = 0; si < e.shelves.length; si++) {
              for (var slot = 0; slot < e.shelves[si].slots.length; slot++) {
                if (e.shelves[si].slots[slot].front?.type == t &&
                    !e.shelves[si].slots[slot].frontBlocked) {
                  e.hammerRemove(BoardPos(si, slot));
                  break outer;
                }
              }
            }
          }
        }
      case BoosterKind.extraShelf:
        e.addExtraShelf();
    }
    var clearing = -1;
    if (e.lastClear != null && e.inputLocked) {
      clearing = e.lastClear!.shelfIndex;
    }
    emit(_snap(banner: _boosterLabel(event.kind), clearingShelf: clearing));
    _flashBanner();
    if (clearing >= 0) _scheduleShelfWave(clearing);
  }

  String _boosterLabel(BoosterKind k) => switch (k) {
        BoosterKind.undo => 'Undo',
        BoosterKind.freeze => 'Frozen 10s!',
        BoosterKind.shuffle => 'Shuffled!',
        BoosterKind.magnet => 'Hammer!',
        BoosterKind.extraShelf => 'Extra shelf!',
      };

  void _onPause(PauseToggled event, Emitter<GameState> emit) {
    _engine?.setPaused(event.paused);
    emit(_snap());
  }

  void _onRestart(GameRestarted event, Emitter<GameState> emit) {
    final level = _engine?.level;
    if (level == null) return;
    _freezeTimer?.cancel();
    _engine = MatchEngine(level: level);
    emit(_snap());
  }

  void _onContinueAfterAd(ContinueAfterAd event, Emitter<GameState> emit) {
    final e = _engine;
    if (e == null) return;
    if (event.extraTime && e.status == GameStatus.lostTime) {
      e.continueWithTime(60);
    } else if (!event.extraTime && e.status == GameStatus.lostSpace) {
      e.continueWithExtraShelf();
    } else if (event.extraTime && e.status == GameStatus.lostSpace) {
      e.continueWithExtraShelf();
    }
    emit(_snap(banner: 'Keep sorting!'));
    _flashBanner();
  }

  void _onBannerCleared(BannerCleared event, Emitter<GameState> emit) {
    if (_engine == null) return;
    emit(_snap(clearBanner: true, clearingShelf: -1, openingShelf: -1));
  }

  void _flashBanner() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(milliseconds: 900), () {
      if (!isClosed) add(const BannerCleared());
    });
  }

  Map<String, dynamic>? toSave() => _engine?.toSaveJson();

  @override
  Future<void> close() {
    _clock?.cancel();
    _mechClock?.cancel();
    _freezeTimer?.cancel();
    _bannerTimer?.cancel();
    _shelfAnimTimer?.cancel();
    _engine?.mechanics.dispose();
    return super.close();
  }
}
