import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../engine/match_engine.dart';
import '../models/shelf.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  MatchEngine? _engine;
  Timer? _clock;
  Timer? _freezeTimer;
  Timer? _bannerTimer;

  GameBloc() : super(const GameState()) {
    on<GameStarted>(_onStarted);
    on<ItemMoved>(_onMoved);
    on<ItemTapped>(_onTapped);
    on<TimerTicked>(_onTick);
    on<BoosterPressed>(_onBooster);
    on<PauseToggled>(_onPause);
    on<GameRestarted>(_onRestart);
    on<BannerCleared>(_onBannerCleared);
  }

  MatchEngine? get engine => _engine;

  GameState _snap({
    String? banner,
    int clearingShelf = -1,
    bool clearBanner = false,
  }) {
    final e = _engine!;
    return GameState(
      level: e.level,
      shelves: e.shelves
          .map((s) => s.copyWith(slots: List<ShelfSlot>.from(s.slots)))
          .toList(),
      belt: const [],
      reserveCount: 0,
      moves: e.moves,
      matches: e.matches,
      combo: e.combo,
      timeLeft: e.timeLeft,
      frozen: e.frozen,
      status: e.status,
      lastClear: e.lastClear,
      banner: clearBanner ? null : banner,
      clearingShelf: clearingShelf,
      ready: true,
      selected: e.selected,
    );
  }

  void _onStarted(GameStarted event, Emitter<GameState> emit) {
    _clock?.cancel();
    _freezeTimer?.cancel();
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
  }

  void _onTapped(ItemTapped event, Emitter<GameState> emit) {
    final e = _engine;
    if (e == null || e.status != GameStatus.playing) return;
    final before = e.matches;
    final ok = e.tap(event.pos);
    if (!ok) {
      emit(_snap());
      return;
    }
    var clearing = -1;
    String? banner;
    if (e.matches > before && e.lastClear != null) {
      clearing = e.lastClear!.shelfIndex;
      banner = e.combo >= 3 ? 'Combo x${e.combo}!' : 'Cleared!';
      _flashBanner();
    }
    emit(_snap(banner: banner, clearingShelf: clearing));
  }

  void _onMoved(ItemMoved event, Emitter<GameState> emit) {
    final e = _engine;
    if (e == null || e.status != GameStatus.playing) return;
    final before = e.matches;
    e.selected = null;
    final ok = e.move(event.from, event.to);
    if (!ok) {
      emit(_snap(banner: 'Can\'t place there'));
      _flashBanner();
      return;
    }
    var clearing = -1;
    String? banner;
    if (e.matches > before && e.lastClear != null) {
      clearing = e.lastClear!.shelfIndex;
      banner = e.combo >= 3 ? 'Combo x${e.combo}!' : 'Cleared!';
      _flashBanner();
    }
    emit(_snap(banner: banner, clearingShelf: clearing));
  }

  void _onTick(TimerTicked event, Emitter<GameState> emit) {
    final e = _engine;
    if (e == null) return;
    if (e.status != GameStatus.playing) return;
    e.tickSecond();
    emit(_snap(banner: state.banner, clearingShelf: state.clearingShelf));
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
        final t = e.dominantType();
        if (t != null) e.magnetClear(t);
      case BoosterKind.extraShelf:
        e.addExtraShelf();
    }
    emit(_snap(banner: _boosterLabel(event.kind)));
    _flashBanner();
  }

  String _boosterLabel(BoosterKind k) => switch (k) {
        BoosterKind.undo => 'Undo',
        BoosterKind.freeze => 'Frozen 10s!',
        BoosterKind.shuffle => 'Shuffled!',
        BoosterKind.magnet => 'Magnet!',
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

  void _onBannerCleared(BannerCleared event, Emitter<GameState> emit) {
    if (_engine == null) return;
    emit(_snap(clearBanner: true, clearingShelf: -1));
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
    _freezeTimer?.cancel();
    _bannerTimer?.cancel();
    return super.close();
  }
}
