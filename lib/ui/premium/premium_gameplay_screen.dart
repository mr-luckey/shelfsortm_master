import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/game_bloc.dart';
import '../../bloc/game_event.dart';
import '../../bloc/game_state.dart';
import '../../data/level_repository.dart';
import '../../engine/match_engine.dart';
import '../../providers/progress_provider.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';
import '../../services/save_service.dart';
import '../screens/level_complete_screen.dart';
import '../screens/shop_screen.dart';
import '../widgets/goods_sort_gameplay_ui.dart';
import 'premium_hud.dart';
import 'premium_shelf_grid.dart';
import 'premium_toolbar.dart';

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
    // The level is built once the board is measured, so its box count always
    // matches the grid that fits on this screen.
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
  int _boxes = 0;

  /// Starts (or rebuilds) the level for the box count the screen can show.
  void _startForBoxes(int boxes) {
    if (boxes == _boxes) return;
    _boxes = boxes;
    final level = widget.daily
        ? LevelRepository.instance.dailyChallenge(DateTime.now(), boxes: boxes)
        : LevelRepository.instance.getLevel(widget.levelId, boxes: boxes);
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BlocConsumer<GameBloc, GameState>(
        listenWhen: (p, c) =>
            p.status != c.status ||
            p.matches != c.matches ||
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
                      PremiumHudBar(
                        coins: progress.progress.coins,
                        gems: progress.progress.gems,
                        level: widget.daily
                            ? widget.levelId
                            : (state.level?.levelId ?? widget.levelId),
                        stars: state.stars,
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
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final boxes =
                                PremiumShelfGrid.boxesFor(c.maxHeight);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _startForBoxes(boxes);
                            });
                            if (!state.ready) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return PremiumShelfGrid(
                              shelves: state.shelves,
                              clearingShelf: state.clearingShelf,
                              inputLocked: state.inputLocked,
                              nextLayers: state.nextLayers,
                              onMove: (from, to) => context
                                  .read<GameBloc>()
                                  .add(ItemMoved(from: from, to: to)),
                            );
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
                    onRestart: () => context
                        .read<GameBloc>()
                        .add(const GameRestarted()),
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
