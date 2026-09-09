import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../bloc/game_bloc.dart';
import '../../bloc/game_event.dart';
import '../../bloc/game_state.dart';
import '../../bloc/gameplay_ui_cubit.dart';
import '../../data/level_repository.dart';
import '../../engine/match_engine.dart';
import '../../models/item.dart';
import '../../models/level_data.dart';
import '../../models/shelf.dart';
import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/ad_service.dart';
import '../../bloc/audio_cubit.dart';
import '../../services/gift_loot.dart';
import '../../services/save_service.dart';
import '../meta/praise_burst.dart';
import '../screens/level_complete_screen.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/gift_box_fab.dart';
import '../widgets/goods_sort_gameplay_ui.dart';
import 'board_drag.dart';
import 'face_images.dart';
import 'premium_goal_panel.dart';
import 'premium_hud.dart';
import 'premium_shelf_grid.dart';
import 'premium_tokens.dart';
import 'premium_toolbar.dart';
import 'premium_tray_belt.dart';
import 'premium_wood_cell.dart';
import '../../engine/mechanics/conveyor_tray.dart';

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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GameBloc()),
        BlocProvider(create: (_) => GameplayUiCubit()),
      ],
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
  int _prevMatches = 0;
  GameStatus? _prevStatus;
  bool _started = false;
  bool _hapticAt10 = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLevel();
      if (mounted) context.read<AudioCubit>().startMusic();
    });
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
    final coins = ProgressProvider.coinsForStars(stars);
    final gems = (!widget.daily && state.status == GameStatus.won)
        ? ProgressProvider.gemsForStars(stars)
        : 0;
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
          gems: gems,
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
    context.read<GameplayUiCubit>().hideLoseOffer();
    context.read<GameBloc>().add(ContinueAfterAd(extraTime: isTime));
  }

  void _showPauseSettings(BuildContext context) {
    MetaPopupScope.show<void>(
      context: context,
      builder: (ctx) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5A3418), Color(0xFF2A1608)],
            ),
            border: Border.all(color: const Color(0xFFE8C45A), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFF7E6C8),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Sound Effects',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(color: Color(0xFFF7E6C8)),
                      ),
                      value: settings.sfx,
                      activeThumbColor: const Color(0xFFE8C45A),
                      onChanged: settings.setSfx,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Music',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(color: Color(0xFFF7E6C8)),
                      ),
                      value: settings.music,
                      activeThumbColor: const Color(0xFFE8C45A),
                      onChanged: settings.setMusic,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Haptics',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(color: Color(0xFFF7E6C8)),
                      ),
                      value: settings.haptics,
                      activeThumbColor: const Color(0xFFE8C45A),
                      onChanged: settings.setHaptics,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          context.read<AudioCubit>().playButton();
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: Color(0xFFE8C45A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
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
        bloc.add(const BoosterPressed(BoosterKind.freeze));
      case BoosterKind.shuffle:
        if (progress.progress.shufflesRemaining <= 0) return;
        await progress.spendShuffle();
        if (context.mounted) {
          bloc.add(const BoosterPressed(BoosterKind.shuffle));
        }
      case BoosterKind.magnet:
        bloc.add(const BoosterPressed(BoosterKind.magnet));
      case BoosterKind.hint:
        bloc.add(const BoosterPressed(BoosterKind.hint));
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
        // The hud, goals and board listen for themselves, so the frame around
        // them only rebuilds when the level or its outcome changes.
        buildWhen: (p, c) =>
            p.status != c.status ||
            p.ready != c.ready ||
            p.level?.levelId != c.level?.levelId ||
            p.level?.timeLimit != c.level?.timeLimit,
        listenWhen: (p, c) =>
            p.status != c.status ||
            p.matches != c.matches ||
            p.moves != c.moves ||
            p.timeLeft != c.timeLeft ||
            (!p.isTerminal && c.isTerminal),
        listener: (context, state) async {
          final audio = context.read<AudioCubit>();
          if (_prevStatus != state.status &&
              state.status == GameStatus.won) {
            audio.playLevelComplete();
          }
          if (_prevStatus != state.status &&
              state.status == GameStatus.paused) {
            audio.playButton();
          }
          _prevStatus = state.status;

          // Pick/place SFX fire instantly on the board drag — only match
          // feedback lives here so place isn't delayed by the Bloc queue.

          if (state.matches > _prevMatches) {
            final gained = state.matches - _prevMatches;
            if (gained >= 2) {
              audio.playCombo();
            } else {
              audio.playShelfComplete();
            }
            final label = audio.playPraise();
            if (mounted) {
              context.read<GameplayUiCubit>().showPraise(label);
              Future<void>.delayed(const Duration(milliseconds: 1100), () {
                if (mounted) {
                  context.read<GameplayUiCubit>().clearPraiseIfSame(label);
                }
              });
            }
          }
          _prevMatches = state.matches;

          if (state.timeLeft == 10 &&
              !_hapticAt10 &&
              state.status == GameStatus.playing) {
            _hapticAt10 = true;
            audio.playInvalid();
          }

          if (state.status == GameStatus.won) {
            await _finish(context, state);
            return;
          }
          if (state.isTerminal) {
            context.read<GameplayUiCubit>().showLoseOffer();
          }
        },
        builder: (context, state) {
          final progress = context.watch<ProgressProvider>();
          final paused = state.status == GameStatus.paused;
          final uiState = context.watch<GameplayUiCubit>().state;
          final showLose = uiState.loseOfferShown &&
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
                          ({int timeLeft, bool frozen})>(
                        selector: (s) => (
                          timeLeft: s.timeLeft,
                          frozen: s.frozen,
                        ),
                        builder: (context, hud) {
                          return PremiumHudBar(
                            coins: progress.progress.coins,
                            level: widget.daily
                                ? widget.levelId
                                : (state.level?.levelId ?? widget.levelId),
                            timeLeft: hud.timeLeft,
                            timeLimit: timeLimit,
                            frozen: hud.frozen,
                            onPause: () => context
                                .read<GameBloc>()
                                .add(const PauseToggled(true)),
                            onAddCoins: null,
                          );
                        },
                      ),
                      if (state.ready)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 8, 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: BlocBuilder<GameBloc, GameState>(
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
                              ),
                              const SizedBox(width: 8),
                              BlocSelector<
                                  GameBloc,
                                  GameState,
                                  ({int freezes, int hints})>(
                                selector: (s) => (
                                  freezes: s.freezesLeft,
                                  hints: s.hintsLeft,
                                ),
                                builder: (context, boost) {
                                  return PremiumBoosterRail(
                                    freezeCount: boost.freezes,
                                    hintCount: boost.hints,
                                    onFreeze: () => _booster(
                                      context,
                                      BoosterKind.freeze,
                                      progress,
                                    ),
                                    onHint: () => _booster(
                                      context,
                                      BoosterKind.hint,
                                      progress,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: !state.ready
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : BlocBuilder<GameBloc, GameState>(
                                buildWhen: (p, c) =>
                                    !setEquals(
                                      p.clearingShelves,
                                      c.clearingShelves,
                                    ) ||
                                    p.inputLocked != c.inputLocked ||
                                    p.level?.levelId != c.level?.levelId ||
                                    p.hintFrom != c.hintFrom ||
                                    p.hintTo != c.hintTo ||
                                    !_sameGoods(p.shelves, c.shelves) ||
                                    !_sameLayers(p.nextLayers, c.nextLayers),
                                builder: (context, board) {
                                  return _PremiumBoardArea(board: board);
                                },
                              ),
                      ),
                      // Room for a banner ad under the board.
                      const AdBannerWidget(placement: 'game'),
                    ],
                  ).animate().fadeIn(duration: 350.ms),
                ),
                Positioned(
                  right: 16,
                  bottom: PremiumTokens.bannerAdHeight + 16,
                  child: GiftBoxFab(
                    pool: GiftLootPool.gameplay,
                    onLoot: (loot) async {
                      final bloc = context.read<GameBloc>();
                      switch (loot) {
                        case GameplayHintLoot():
                          bloc.add(const GiftBoosterGranted(
                            GiftBoosterKind.hint,
                          ));
                        case GameplayFreezeLoot():
                          bloc.add(const GiftBoosterGranted(
                            GiftBoosterKind.freeze,
                          ));
                        case GameplayTimeLoot(:final seconds):
                          bloc.add(GiftBoosterGranted(
                            GiftBoosterKind.extraTime,
                            extraSeconds: seconds,
                          ));
                        default:
                          break;
                      }
                    },
                  ),
                ),
                if (paused)
                  GoodsSortPauseOverlay(
                    onResume: () {
                      context
                          .read<GameBloc>()
                          .add(const PauseToggled(false));
                    },
                    onRestart: () {
                      _hapticAt10 = false;
                      _prevMatches = 0;
                      context
                          .read<GameBloc>()
                          .add(const GameRestarted());
                    },
                    onQuit: () => Navigator.pop(context),
                    onHome: () => Navigator.pop(context),
                    onSettings: () => _showPauseSettings(context),
                  ),
                if (uiState.praise != null)
                  PraiseBurst(
                    key: ValueKey(uiState.praiseSeq),
                    label: uiState.praise!,
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

/// Whether two board snapshots hold the same goods in the same places.
///
/// Every emitted state carries fresh shelf objects, so the board only rebuilds
/// when the goods themselves changed.
bool _sameGoods(List<Shelf> a, List<Shelf> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final left = a[i].slots;
    final right = b[i].slots;
    if (left.length != right.length) return false;
    for (var s = 0; s < left.length; s++) {
      if (left[s].stack.length != right[s].stack.length) return false;
      if (left[s].accessible != right[s].accessible) return false;
      if (left[s].frontBlocked != right[s].frontBlocked) return false;
      for (var k = 0; k < left[s].stack.length; k++) {
        if (left[s].stack[k].id != right[s].stack[k].id) return false;
      }
    }
  }
  return true;
}

bool _sameLayers(List<List<GameItem?>?> a, List<List<GameItem?>?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final left = a[i];
    final right = b[i];
    if (left == null || right == null) {
      if (left != right) return false;
      continue;
    }
    if (left.length != right.length) return false;
    for (var s = 0; s < left.length; s++) {
      if (left[s]?.id != right[s]?.id) return false;
    }
  }
  return true;
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
  final GlobalKey _ghostKey = GlobalKey();
  late final Listenable _ghostRepaint;

  @override
  void initState() {
    super.initState();
    _drag = BoardDragController();
    _ghostRepaint = Listenable.merge([
      _drag.held,
      _drag.finger,
      FaceImages.instance,
    ]);
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
                clearingShelves: board.clearingShelves,
                inputLocked: board.inputLocked,
                nextLayers: board.nextLayers,
                hintFrom: board.hintFrom,
                hintTo: board.hintTo,
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
                    clearingShelves: board.clearingShelves,
                    nextLayers: board.nextLayers,
                  ),
                ),
              ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                key: _ghostKey,
                painter: _HeldGoodPainter(
                  drag: _drag,
                  faces: FaceImages.instance,
                  overlay: _ghostKey,
                  repaint: _ghostRepaint,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Draws the good in the player's hand above both halves of the board.
class _HeldGoodPainter extends CustomPainter {
  final BoardDragController drag;
  final FaceImages faces;
  final GlobalKey overlay;

  /// Size the carried good is drawn at, a little larger than on the shelf.
  static const double goodSize = 62;

  _HeldGoodPainter({
    required this.drag,
    required this.faces,
    required this.overlay,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final held = drag.held.value;
    if (held == null) return;
    final image = faces.of(held.type);
    if (image == null) return;
    final box = overlay.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final local = box.globalToLocal(drag.finger.value);
    // Lifted goods hang just above the finger so the shelf stays visible.
    final center = Offset(local.dx, local.dy - goodSize * 0.22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + goodSize * 0.52),
        width: goodSize * 0.5,
        height: goodSize * 0.14,
      ),
      Paint()
        ..color = const Color(0xFF1B0F02).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    drawFace(
      canvas,
      image,
      Rect.fromCenter(center: center, width: goodSize, height: goodSize),
      null,
    );
  }

  @override
  bool shouldRepaint(covariant _HeldGoodPainter old) => true;
}
