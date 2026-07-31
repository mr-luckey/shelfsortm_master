import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/app_colors.dart';
import '../../bloc/game_bloc.dart';
import '../../bloc/game_event.dart';
import '../../bloc/game_state.dart';
import '../../data/level_repository.dart';
import '../../engine/match_engine.dart';
import '../../models/level_data.dart';
import '../../providers/progress_provider.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';
import '../../services/save_service.dart';
import '../theme/shelf_look.dart';
import '../widgets/cupboard_board.dart';
import '../widgets/goods_sort_gameplay_ui.dart';
import '../widgets/mechanic_widgets.dart';
import 'level_complete_screen.dart';

/// Goods Sort™ gameplay — cream cabinet layout, emoji items, no popups.
class GameplayScreen extends StatelessWidget {
  final int levelId;
  final bool daily;

  const GameplayScreen({
    super.key,
    required this.levelId,
    this.daily = false,
  });

  @override
  Widget build(BuildContext context) {
    final level = daily
        ? LevelRepository.instance.dailyChallenge(DateTime.now())
        : LevelRepository.instance.getLevel(levelId);

    return BlocProvider(
      create: (_) => GameBloc()..add(GameStarted(level)),
      child: _View(levelId: levelId, daily: daily),
    );
  }
}

class _View extends StatefulWidget {
  final int levelId;
  final bool daily;

  const _View({required this.levelId, required this.daily});

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  bool _loseOfferShown = false;
  int _prevMatches = 0;
  int _prevCombo = 0;
  GameStatus? _prevStatus;

  String _fmt(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _pause(BuildContext context) {
    context.read<GameBloc>().add(const PauseToggled(true));
  }

  Future<void> _watchAdContinue(BuildContext context, GameState state) async {
    final isTime = state.status == GameStatus.lostTime;
    final ads = context.read<AdService>();
    final ok = await ads.showRewarded(
      isTime ? RewardType.hint : RewardType.extraShelf,
    );
    if (!ok || !context.mounted) return;
    setState(() => _loseOfferShown = false);
    context.read<GameBloc>().add(ContinueAfterAd(extraTime: isTime));
  }

  void _playFeedback(BuildContext context, GameState state) {
    final audio = context.read<AudioService>();
    if (_prevStatus != state.status) {
      if (state.status == GameStatus.won) {
        audio.playLevelComplete();
      }
      _prevStatus = state.status;
    }
    if (state.matches > _prevMatches) {
      audio.playShelfComplete();
      if (state.combo >= 3 && state.combo > _prevCombo) {
        audio.playCombo();
      }
    }
    _prevMatches = state.matches;
    _prevCombo = state.combo;
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
                  ? 'Shelves locked — no empty slots!'
                  : null,
        ),
        transitionsBuilder: (_, anim, secondary, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
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

  BoosterKind? _boosterFromId(String id) => switch (id) {
        'undo' => BoosterKind.undo,
        'freeze' => BoosterKind.freeze,
        'shuffle' => BoosterKind.shuffle,
        'hammer' => BoosterKind.magnet,
        'shelf' => BoosterKind.extraShelf,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listenWhen: (p, c) =>
          p.status != c.status ||
          p.matches != c.matches ||
          p.combo != c.combo ||
          (!p.isTerminal && c.isTerminal),
      listener: (context, state) async {
        _playFeedback(context, state);
        if (state.status == GameStatus.won) {
          await _finish(context, state);
          return;
        }
        if (state.isTerminal && !_loseOfferShown) {
          setState(() => _loseOfferShown = true);
        }
      },
      builder: (context, state) {
        if (!state.ready) {
          return Scaffold(
            body: Container(
              decoration: GoodsSortLayout.screenBg,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
            ),
          );
        }

        final progress = context.watch<ProgressProvider>();
        final setsLeft = (state.itemCount / 3).ceil();
        final totalSets = state.matches + setsLeft;
        final progressRatio = totalSets > 0 ? state.matches / totalSets : 0.0;
        final trayPos =
            (state.mechanicVisual['trayPosition'] as num?)?.toDouble() ?? 0;
        final hasConveyor = state.belt.isNotEmpty;
        final hasMovingTray =
            state.activeMechanics.contains('moving_bottom_tray');
        final layout = state.level?.resolvedLayout() ??
            LevelData.defaultLayout(state.shelves.length);
        final scale = state.shelves.length > 10
            ? 0.82
            : state.shelves.length > 7
                ? 0.9
                : 1.0;
        final theme = state.level?.theme;
        final look = ShelfLook.forStyle(theme?.shelfStyle ?? 'oak');
        final spice = spiceForLevel(
          state.level?.levelId ?? widget.levelId,
          theme?.shelfStyle ?? 'oak',
        );
        final levelLabel = widget.daily
            ? 'Daily'
            : 'Level ${state.level?.levelId ?? widget.levelId}';
        final showLose = _loseOfferShown &&
            (state.status == GameStatus.lostTime ||
                state.status == GameStatus.lostSpace);
        final paused = state.status == GameStatus.paused;

        return Scaffold(
          body: Container(
            decoration: GoodsSortLayout.screenBg,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      GoodsSortTopBar(
                        levelText: levelLabel,
                        timeText: _fmt(state.timeLeft),
                        urgent: state.timeLeft <= 15 && !state.frozen,
                        frozen: state.frozen,
                        onSettings: () => _pause(context),
                        onBack: () => Navigator.pop(context),
                      ),
                      GoodsSortProgressBar(ratio: progressRatio),
                      Expanded(
                        child: GoodsSortCupboard(
                          child: CupboardBoard(
                            layout: layout,
                            shelves: state.shelves,
                            selected: state.inputLocked
                                ? null
                                : state.selected,
                            clearingShelf: state.clearingShelf,
                            openingShelf: state.openingShelf,
                            finishedShelves: state.finishedShelves,
                            scale: scale,
                            look: look,
                            spice: spice,
                            onTap: state.inputLocked
                                ? (_) {}
                                : (pos) {
                                    context.read<AudioService>().playPick();
                                    context.read<GameBloc>().add(
                                          ItemTapped(pos),
                                        );
                                  },
                            onMove: state.inputLocked
                                ? (_, __) {}
                                : (from, to) {
                                    context.read<AudioService>().playPlace();
                                    context.read<GameBloc>().add(
                                          ItemMoved(
                                            from: from,
                                            to: to,
                                          ),
                                        );
                                  },
                          ),
                        ),
                      ),
                      if (hasConveyor)
                        ConveyorBeltRow(
                          belt: state.belt,
                          accent: ShelfLookAccent(color: look.accent),
                        ),
                      if (hasMovingTray)
                        MovingTrayBar(
                          position: trayPos,
                          accent: look.accent,
                        ),
                      GoodsSortBoosterBar(
                        freezes: progress.progress.hintsRemaining,
                        shuffles: progress.progress.shufflesRemaining,
                        hammers: progress.progress.autoSortRemaining,
                        extras: progress.progress.extraShelfRemaining,
                        onPressed: (id) {
                          final kind = _boosterFromId(id);
                          if (kind != null) {
                            _booster(context, kind, progress);
                          }
                        },
                      ),
                    ],
                  ),
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
          ),
        );
      },
    );
  }
}
