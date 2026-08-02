import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/game_bloc.dart';
import '../../bloc/game_event.dart';
import '../../bloc/game_state.dart';
import '../../data/level_repository.dart';
import '../../engine/match_engine.dart';
import '../../models/item.dart';
import '../../models/level_data.dart';
import '../../providers/progress_provider.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';
import '../../services/save_service.dart';
import '../screens/level_complete_screen.dart';
import '../screens/shop_screen.dart';
import '../widgets/goods_sort_gameplay_ui.dart';
import 'premium_goal_panel.dart';
import 'premium_hud.dart';
import 'premium_shelf_grid.dart';
import 'premium_toolbar.dart';
import 'premium_tray_belt.dart';
import 'board_drag.dart';
import '../../engine/mechanics/conveyor_tray.dart';
import '../widgets/emoji_assets.dart';

/// Premium UI + real MatchEngine gameplay (tap/drag match-3, waves, boosters).
class PremiumGameplayScreen extends StatelessWidget {
  final int levelId;
  final bool daily;

  const PremiumGameplayScreen({
    super.key,
    required this.levelId,
    this.daily = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameBloc(),
      child: _PremiumPlayView(levelId: levelId, daily: daily),
    );
  }
}

class _PremiumPlayView extends StatefulWidget {
  final int levelId;
  final bool daily;

  const _PremiumPlayView({required this.levelId, required this.daily});

  @override
  State<_PremiumPlayView> createState() => _PremiumPlayViewState();
}

class _PremiumPlayViewState extends State<_PremiumPlayView> {
  bool _loseOfferShown = false;
  int _prevMatches = 0;
  GameStatus? _prevStatus;
  bool _started = false;
  bool _hapticAt10 = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startLevel());
  }

  void _startLevel() {
    if (_started || !mounted) return;
    _started = true;
    final level = widget.daily
        ? LevelRepository.instance.dailyChallenge(DateTime.now())
        : LevelRepository.instance.getLevel(widget.levelId);
    context.read<GameBloc>().add(GameStarted(level));
  }

  Future<void> _finish(BuildContext context, GameState state) async {
    final progress = context.read<ProgressProvider>();
    await context.read<SaveService>().clearMidLevel();
    final stars = state.stars;
    final coins = stars * 10 + state.matches * 2;
    if (widget.daily) {
      await progress.completeDailyChallenge(coins: 80 + coins);
    } else if (state.status == GameStatus.won) {
      await progress.completeLevel(
        levelId: widget.levelId,
        stars: stars,
        moves: state.moves,
        coinsEarned: coins,
      );
    }
    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, anim, secondary) => LevelCompleteScreen(
          levelId: widget.levelId,
          stars: stars,
          moves: state.moves,
          coins: coins,
          won: state.status == GameStatus.won,
          timeLeft: state.timeLeft,
          daily: widget.daily,
          loseReason: state.status == GameStatus.lostTime
              ? 'Time is up!'
              : state.status == GameStatus.lostSpace
                  ? 'No empty slots left!'
                  : null,
        ),
        transitionsBuilder: (_, anim, secondary, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _watchAdContinue(BuildContext context, GameState state) async {
    final isTime = state.status == GameStatus.lostTime;
    final ok = await context.read<AdService>().showRewarded(
          isTime ? RewardType.hint : RewardType.extraShelf,
        );
    if (!ok || !context.mounted) return;
    setState(() => _loseOfferShown = false);
    context.read<GameBloc>().add(ContinueAfterAd(extraTime: isTime));
  }

  Future<void> _booster(
    BuildContext context,
    BoosterKind kind,
    ProgressProvider progress,
  ) async {
    final bloc = context.read<GameBloc>();
    switch (kind) {
      case BoosterKind.undo:
        bloc.add(const BoosterPressed(BoosterKind.undo));
      case BoosterKind.freeze:
        if (progress.progress.hintsRemaining <= 0) return;
        await progress.spendHint();
        if (context.mounted) {
          bloc.add(const BoosterPressed(BoosterKind.freeze));
        }
      case BoosterKind.shuffle:
        if (progress.progress.shufflesRemaining <= 0) return;
        await progress.spendShuffle();
        if (context.mounted) {
          bloc.add(const BoosterPressed(BoosterKind.shuffle));
        }
      case BoosterKind.magnet:
        if (progress.progress.autoSortRemaining <= 0) return;
        await progress.spendAutoSort();
        if (context.mounted) {
          bloc.add(const BoosterPressed(BoosterKind.magnet));
        }
      case BoosterKind.extraShelf:
        if (progress.progress.extraShelfRemaining <= 0) return;
        await progress.spendExtraShelf();
        if (context.mounted) {
          bloc.add(const BoosterPressed(BoosterKind.extraShelf));
        }
    }
  }

  List<({String type, int remaining})> _goalsFrom(GameState state) {
    final counts = <String, int>{};
    void addItem(GameItem? item) {
      if (item == null) return;
      counts[item.type] = (counts[item.type] ?? 0) + 1;
    }

    for (final shelf in state.shelves) {
      for (final slot in shelf.slots) {
        for (final item in slot.stack) {
          addItem(item);
        }
      }
    }
    for (final layer in state.nextLayers) {
      if (layer == null) continue;
      for (final item in layer) {
        addItem(item);
      }
    }

    final goals = [
      for (final e in counts.entries)
        (type: e.key, remaining: (e.value / 3).ceil()),
    ]..sort((a, b) => b.remaining.compareTo(a.remaining));
    return goals.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BlocConsumer<GameBloc, GameState>(
        listenWhen: (p, c) =>
            p.status != c.status ||
            p.matches != c.matches ||
            p.timeLeft != c.timeLeft ||
            (!p.isTerminal && c.isTerminal),
        listener: (context, state) async {
          final audio = context.read<AudioService>();
          if (_prevStatus != state.status &&
              state.status == GameStatus.won) {
            audio.playLevelComplete();
          }
          _prevStatus = state.status;
          if (state.matches > _prevMatches) {
            audio.playShelfComplete();
          }
          _prevMatches = state.matches;

          if (state.timeLeft == 10 &&
              !_hapticAt10 &&
              state.status == GameStatus.playing) {
            _hapticAt10 = true;
            HapticFeedback.lightImpact();
          }

          if (state.status == GameStatus.won) {
            await _finish(context, state);
            return;
          }
          if (state.isTerminal && !_loseOfferShown) {
            setState(() => _loseOfferShown = true);
          }
        },
        builder: (context, state) {
          final progress = context.watch<ProgressProvider>();
          final paused = state.status == GameStatus.paused;
          final showLose = _loseOfferShown &&
              (state.status == GameStatus.lostTime ||
                  state.status == GameStatus.lostSpace);
          final timeLimit = state.level?.timeLimit ?? 1;

          return Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/rooms/premium_room_bg.png',
                  fit: BoxFit.cover,
                ),
                SafeArea(
                  child: Column(
                    children: [
                      BlocSelector<GameBloc, GameState,
                          ({int timeLeft, bool frozen, int stars})>(
                        selector: (s) => (
                          timeLeft: s.timeLeft,
                          frozen: s.frozen,
                          stars: s.stars,
                        ),
                        builder: (context, hud) {
                          return PremiumHudBar(
                            coins: progress.progress.coins,
                            gems: progress.progress.gems,
                            level: widget.daily
                                ? widget.levelId
                                : (state.level?.levelId ?? widget.levelId),
                            stars: hud.stars,
                            timeLeft: hud.timeLeft,
                            timeLimit: timeLimit,
                            frozen: hud.frozen,
                            onSettings: () => context
                                .read<GameBloc>()
                                .add(const PauseToggled(true)),
                            onShop: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ShopScreen(),
                                ),
                              );
                            },
                            onAddCoins: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ShopScreen(),
                                ),
                              );
                            },
                            onAddGems: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ShopScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      if (state.ready)
                        BlocBuilder<GameBloc, GameState>(
                          buildWhen: (p, c) =>
                              p.itemCount != c.itemCount ||
                              p.matches != c.matches,
                          builder: (context, goalState) {
                            return PremiumGoalPanel(
                              goals: _goalsFrom(goalState),
                              goalText: 'Clear all sets',
                            );
                          },
                        ),
                      Expanded(
                        child: !state.ready
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : BlocBuilder<GameBloc, GameState>(
                                buildWhen: (p, c) =>
                                    p.shelves != c.shelves ||
                                    p.clearingShelf != c.clearingShelf ||
                                    p.inputLocked != c.inputLocked ||
                                    p.nextLayers != c.nextLayers ||
                                    p.level?.levelId != c.level?.levelId,
                                builder: (context, board) {
                                  return _PremiumBoardArea(board: board);
                                },
                              ),
                      ),
                      PremiumActionToolbar(
                        undoCount: 99,
                        shuffleCount:
                            progress.progress.shufflesRemaining,
                        freezeCount: progress.progress.hintsRemaining,
                        extraCount:
                            progress.progress.extraShelfRemaining,
                        hintCount:
                            progress.progress.autoSortRemaining,
                        onUndo: () => _booster(
                          context,
                          BoosterKind.undo,
                          progress,
                        ),
                        onShuffle: () => _booster(
                          context,
                          BoosterKind.shuffle,
                          progress,
                        ),
                        onFreeze: () => _booster(
                          context,
                          BoosterKind.freeze,
                          progress,
                        ),
                        onExtraSlot: () => _booster(
                          context,
                          BoosterKind.extraShelf,
                          progress,
                        ),
                        onHint: () => _booster(
                          context,
                          BoosterKind.magnet,
                          progress,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 350.ms),
                ),
                if (paused)
                  GoodsSortPauseOverlay(
                    onResume: () => context
                        .read<GameBloc>()
                        .add(const PauseToggled(false)),
                    onRestart: () {
                      _hapticAt10 = false;
                      context
                          .read<GameBloc>()
                          .add(const GameRestarted());
                    },
                    onQuit: () => Navigator.pop(context),
                  ),
                if (showLose)
                  GoodsSortLoseOverlay(
                    isTime: state.status == GameStatus.lostTime,
                    onWatchAd: () => _watchAdContinue(context, state),
                    onQuit: () => _finish(context, state),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Cupboard + optional tray belt, sharing one drag so goods can move between.
class _PremiumBoardArea extends StatefulWidget {
  final GameState board;

  const _PremiumBoardArea({required this.board});

  @override
  State<_PremiumBoardArea> createState() => _PremiumBoardAreaState();
}

class _PremiumBoardAreaState extends State<_PremiumBoardArea> {
  late final BoardDragController _drag;

  @override
  void initState() {
    super.initState();
    _drag = BoardDragController();
  }

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  void _onMove(BoardPos from, BoardPos to) {
    context.read<GameBloc>().add(ItemMoved(from: from, to: to));
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    final level = board.level;
    final layout =
        level?.resolvedLayout() ?? LevelData.defaultLayout(board.shelves.length);
    final tray = context
        .read<GameBloc>()
        .engine
        ?.mechanics
        .ofType<ConveyorTrayMechanic>();
    final trayIndices = tray?.trayShelfIndices ?? const <int>[];
    final showBelt = tray != null && trayIndices.isNotEmpty;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: PremiumShelfGrid(
                layout: layout,
                shelves: board.shelves,
                clearingShelf: board.clearingShelf,
                inputLocked: board.inputLocked,
                nextLayers: board.nextLayers,
                drag: _drag,
                onMove: _onMove,
              ),
            ),
            if (showBelt)
              Padding(
                padding: PremiumTrayBelt.beltPadding,
                child: SizedBox(
                  height: PremiumTrayBelt.height,
                  child: PremiumTrayBelt(
                    shelves: board.shelves,
                    trayIndices: trayIndices,
                    mechanic: tray,
                    inputLocked: board.inputLocked,
                    drag: _drag,
                    onMove: _onMove,
                  ),
                ),
              ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder<HeldGood?>(
              valueListenable: _drag.held,
              builder: (context, held, _) {
                if (held == null) return const SizedBox.shrink();
                return ValueListenableBuilder<Offset>(
                  valueListenable: _drag.finger,
                  builder: (context, finger, _) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box == null || !box.hasSize) {
                      return const SizedBox.shrink();
                    }
                    final local = box.globalToLocal(finger);
                    const size = 56.0;
                    return Stack(
                      children: [
                        Positioned(
                          left: local.dx - size / 2,
                          top: local.dy - size / 2 - 10,
                          width: size,
                          height: size,
                          child: Image.asset(
                            EmojiAssets.pathFor(held.type),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, error, stack) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
