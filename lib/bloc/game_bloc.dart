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
  Timer? _openTimer;
  Timer? _hintTimer;

  /// One sale timer per box, keyed by shelf index.
  final Map<int, Timer> _saleTimers = {};

  /// Length of the sale animation the board plays; see `FxTiming.sell`.
  static const Duration _saleDuration = Duration(milliseconds: 720);

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
    on<HintCleared>(_onHintCleared);
    on<ShelfWaveOpened>(_onShelfWaveOpened);
    on<ContinueAfterAd>(_onContinueAfterAd);
    on<GiftBoosterGranted>(_onGiftBoosterGranted);
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
    int openingShelf = -1,
    bool clearBanner = false,
    int? freezesLeft,
    int? hintsLeft,
    BoardPos? hintFrom,
    BoardPos? hintTo,
    bool clearHint = false,
    bool resetBoosters = false,
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
      clearingShelves: e.closingShelves,
      clearingShelf: e.closingShelves.isEmpty ? -1 : e.closingShelves.first,
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
      freezesLeft: resetBoosters
          ? GameState.freezesPerLevel
          : (freezesLeft ?? state.freezesLeft),
      hintsLeft: resetBoosters
          ? GameState.hintsPerLevel
          : (hintsLeft ?? state.hintsLeft),
      hintFrom: clearHint ? null : (hintFrom ?? state.hintFrom),
      hintTo: clearHint ? null : (hintTo ?? state.hintTo),
    );
  }

  void _onStarted(GameStarted event, Emitter<GameState> emit) {
    _clock?.cancel();
    _mechClock?.cancel();
    _freezeTimer?.cancel();
    _bannerTimer?.cancel();
    _hintTimer?.cancel();
    _cancelSales();
    _engine = MatchEngine(level: event.level);
    if (event.midSave != null) {
      try {
        _engine!.loadSaveJson(event.midSave!);
      } catch (_) {}
    }
    emit(_snap(resetBoosters: true, clearHint: true));
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
      emit(_snap(clearHint: true));
      return;
    }
    String? banner;
    if (e.matches > before && e.lastClear != null) {
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
    emit(_snap(banner: banner, clearHint: true));
    _scheduleSales();
  }

  void _onMoved(ItemMoved event, Emitter<GameState> emit) {
    final e = _engine;
    if (e == null || e.status != GameStatus.playing) return;
    final before = e.matches;
    e.selected = null;
    final ok = e.move(event.from, event.to);
    if (!ok) {
      emit(_snap(banner: 'Need an empty slot', clearHint: true));
      _flashBanner();
      return;
    }
    String? banner;
    if (e.matches > before && e.lastClear != null) {
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
    emit(_snap(banner: banner, clearHint: true));
    _scheduleSales();
  }

  /// Every box that just matched runs its own sale, so a second match never cuts
  /// the first one short.
  void _scheduleSales() {
    final e = _engine;
    if (e == null) return;
    for (final shelfIndex in e.closingShelves) {
      if (_saleTimers.containsKey(shelfIndex)) continue;
      _saleTimers[shelfIndex] = Timer(_saleDuration, () {
        _saleTimers.remove(shelfIndex);
        if (isClosed || _engine == null) return;
        _engine!.finishShelfClose(shelfIndex);
        if (_engine!.waves.hasPendingWave(shelfIndex)) {
          add(ShelfWaveOpened(shelfIndex));
        } else {
          add(const BannerCleared());
        }
      });
    }
  }

  void _onShelfWaveOpened(ShelfWaveOpened event, Emitter<GameState> emit) {
    final e = _engine;
    if (e == null) return;
    e.openNextWave(event.shelfIndex);
    emit(_snap(openingShelf: event.shelfIndex));
    _openTimer?.cancel();
    _openTimer = Timer(const Duration(milliseconds: 480), () {
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
      openingShelf: state.openingShelf,
    ));
  }

  void _onBooster(BoosterPressed event, Emitter<GameState> emit) {
    final e = _engine;
    if (e == null || e.status != GameStatus.playing) return;

    switch (event.kind) {
      case BoosterKind.undo:
        e.undo();
        emit(_snap(banner: _boosterLabel(event.kind), clearHint: true));
      case BoosterKind.freeze:
        if (state.freezesLeft <= 0) return;
        e.setFrozen(true);
        _freezeTimer?.cancel();
        _freezeTimer = Timer(const Duration(seconds: 10), () {
          _engine?.setFrozen(false);
          if (!isClosed) add(const BannerCleared());
        });
        emit(_snap(
          banner: _boosterLabel(event.kind),
          freezesLeft: state.freezesLeft - 1,
        ));
      case BoosterKind.shuffle:
        e.shuffleBoard();
        emit(_snap(banner: _boosterLabel(event.kind), clearHint: true));
      case BoosterKind.magnet:
        // Classic Hammer: remove one blocking front item.
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
        emit(_snap(banner: _boosterLabel(event.kind), clearHint: true));
      case BoosterKind.hint:
        if (state.hintsLeft <= 0) return;
        final move = e.findHintMove();
        if (move == null) {
          emit(_snap(banner: 'No move found'));
          _flashBanner();
          return;
        }
        emit(_snap(
          banner: _boosterLabel(event.kind),
          hintsLeft: state.hintsLeft - 1,
          hintFrom: move.from,
          hintTo: move.to,
        ));
        _hintTimer?.cancel();
        _hintTimer = Timer(const Duration(seconds: 4), () {
          if (!isClosed) add(const HintCleared());
        });
      case BoosterKind.extraShelf:
        e.addExtraShelf();
        emit(_snap(banner: _boosterLabel(event.kind), clearHint: true));
    }
    _flashBanner();
    _scheduleSales();
  }

  String _boosterLabel(BoosterKind k) => switch (k) {
        BoosterKind.undo => 'Undo',
        BoosterKind.freeze => 'Frozen 10s!',
        BoosterKind.shuffle => 'Shuffled!',
        BoosterKind.magnet => 'Hammer!',
        BoosterKind.hint => 'Follow the hand!',
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
    _hintTimer?.cancel();
    _cancelSales();
    _engine = MatchEngine(level: level);
    emit(_snap(resetBoosters: true, clearHint: true));
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

  void _onGiftBoosterGranted(
    GiftBoosterGranted event,
    Emitter<GameState> emit,
  ) {
    final e = _engine;
    if (e == null) return;
    if (e.status != GameStatus.playing && e.status != GameStatus.paused) {
      return;
    }
    switch (event.kind) {
      case GiftBoosterKind.hint:
        emit(_snap(
          hintsLeft: state.hintsLeft + 1,
          banner: '+1 Hint!',
        ));
      case GiftBoosterKind.freeze:
        emit(_snap(
          freezesLeft: state.freezesLeft + 1,
          banner: '+1 Freeze!',
        ));
      case GiftBoosterKind.extraTime:
        e.addBonusTime(event.extraSeconds);
        emit(_snap(banner: '+${event.extraSeconds}s!'));
    }
    _flashBanner();
  }

  void _onBannerCleared(BannerCleared event, Emitter<GameState> emit) {
    if (_engine == null) return;
    emit(_snap(clearBanner: true, openingShelf: -1));
  }

  void _onHintCleared(HintCleared event, Emitter<GameState> emit) {
    if (_engine == null) return;
    emit(_snap(clearHint: true));
  }

  void _flashBanner() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(milliseconds: 900), () {
      if (!isClosed) add(const BannerCleared());
    });
  }

  void _cancelSales() {
    for (final timer in _saleTimers.values) {
      timer.cancel();
    }
    _saleTimers.clear();
    _openTimer?.cancel();
  }

  Map<String, dynamic>? toSave() => _engine?.toSaveJson();

  @override
  Future<void> close() {
    _clock?.cancel();
    _mechClock?.cancel();
    _freezeTimer?.cancel();
    _bannerTimer?.cancel();
    _hintTimer?.cancel();
    _cancelSales();
    _engine?.mechanics.dispose();
    return super.close();
  }
}
