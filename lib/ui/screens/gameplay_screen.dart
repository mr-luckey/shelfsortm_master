import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/app_colors.dart';
import '../../bloc/game_bloc.dart';
import '../../bloc/game_event.dart';
import '../../bloc/game_state.dart';
import '../../data/level_repository.dart';
import '../../engine/match_engine.dart';
import '../../models/level_data.dart';
import '../../models/shelf.dart';
import '../../providers/progress_provider.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';
import '../../services/save_service.dart';
import '../theme/shelf_look.dart';
import '../widgets/mechanic_widgets.dart';
import '../widgets/pixel_shelf.dart';
import '../widgets/store_background.dart';
import 'level_complete_screen.dart';
import 'mechanic_tutorial.dart';

/// Sort Challenge — open wooden shelves + theme variety per level.
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
  bool _tutorialChecked = false;
  bool _loseOfferShown = false;
  int _prevMatches = 0;
  int _prevCombo = 0;
  GameStatus? _prevStatus;

  String _fmt(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _maybeShowMechanicTutorial(List<String> mechanics) async {
    if (_tutorialChecked || mechanics.isEmpty) return;
    _tutorialChecked = true;
    final id = await MechanicTutorials.firstUnseen(mechanics);
    if (id == null || !mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MechanicTutorialSheet(
        mechanicId: id,
        onDismiss: () => Navigator.pop(ctx),
      ),
    );
  }

  void _pause(BuildContext context) {
    context.read<GameBloc>().add(const PauseToggled(true));
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2A3344),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFC4A070), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paused',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<GameBloc>().add(const PauseToggled(false));
                },
                child: const Text('Resume'),
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<GameBloc>().add(const GameRestarted());
              },
              child: const Text('Restart'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Exit', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _offerContinue(BuildContext context, GameState state) async {
    final isTime = state.status == GameStatus.lostTime;
    final ads = context.read<AdService>();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(isTime ? 'Time\'s up!' : 'Shelves locked!'),
        content: Text(
          isTime
              ? 'Watch a short ad to get +60 seconds and keep sorting.'
              : 'Watch a short ad to add an extra shelf and continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Give up'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Watch ad'),
          ),
        ],
      ),
    );
    if (result != true || !context.mounted) return false;
    final ok = await ads.showRewarded(
      isTime ? RewardType.hint : RewardType.extraShelf,
    );
    if (!ok || !context.mounted) return false;
    context.read<GameBloc>().add(
          ContinueAfterAd(extraTime: isTime),
        );
    return true;
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
    Future<bool> gate(int count, RewardType reward, String name) async {
      if (count > 0) return true;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Need $name?'),
          content: const Text('Watch ad for +1 (optional).'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Watch'),
            ),
          ],
        ),
      );
      if (ok == true) {
        await progress.watchAdForTool(reward);
        return true;
      }
      return false;
    }

    final bloc = context.read<GameBloc>();
    switch (kind) {
      case BoosterKind.undo:
        bloc.add(const BoosterPressed(BoosterKind.undo));
      case BoosterKind.freeze:
        if (!await gate(
          progress.progress.hintsRemaining,
          RewardType.hint,
          'Freeze',
        )) {
          return;
        }
        if (progress.progress.hintsRemaining > 0) await progress.spendHint();
        if (context.mounted) {
          bloc.add(const BoosterPressed(BoosterKind.freeze));
        }
      case BoosterKind.shuffle:
        if (!await gate(
          progress.progress.shufflesRemaining,
          RewardType.shuffle,
          'Refresh',
        )) {
          return;
        }
        if (progress.progress.shufflesRemaining > 0) {
          await progress.spendShuffle();
        }
        if (context.mounted) {
          bloc.add(const BoosterPressed(BoosterKind.shuffle));
        }
      case BoosterKind.magnet:
        if (!await gate(
          progress.progress.autoSortRemaining,
          RewardType.autoSort,
          'Hammer',
        )) {
          return;
        }
        if (progress.progress.autoSortRemaining > 0) {
          await progress.spendAutoSort();
        }
        if (context.mounted) {
          bloc.add(const BoosterPressed(BoosterKind.magnet));
        }
      case BoosterKind.extraShelf:
        if (!await gate(
          progress.progress.extraShelfRemaining,
          RewardType.extraShelf,
          'Shelf',
        )) {
          return;
        }
        if (progress.progress.extraShelfRemaining > 0) {
          await progress.spendExtraShelf();
        }
        if (context.mounted) {
          bloc.add(const BoosterPressed(BoosterKind.extraShelf));
        }
    }
  }

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
          _loseOfferShown = true;
          final continued = await _offerContinue(context, state);
          if (continued) {
            _loseOfferShown = false;
            return;
          }
          if (context.mounted) await _finish(context, state);
        }
      },
      builder: (context, state) {
        if (!state.ready) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A2332),
            body: Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
          );
        }

        final progress = context.watch<ProgressProvider>();
        final timeColor = state.timeLeft <= 15
            ? const Color(0xFFFF5252)
            : state.frozen
                ? const Color(0xFF4FC3F7)
                : const Color(0xFF3E2723);
        final setsLeft = (state.itemCount / 3).ceil();
        final totalSets = state.matches + setsLeft;
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

        if (state.activeMechanics.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeShowMechanicTutorial(state.activeMechanics);
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5EDE0),
          body: Stack(
            fit: StackFit.expand,
            children: [
              StoreBackground(
                colors: look.roomBg,
                moodEmoji: theme?.emoji ?? look.moodEmoji,
              ),
              SafeArea(
                child: Column(
                  children: [
                    _GoodsSortHeader(
                      levelLabel: widget.daily
                          ? 'Daily Challenge'
                          : 'Level ${state.level?.levelId ?? widget.levelId}',
                      time: _fmt(state.timeLeft),
                      timeColor: timeColor,
                      frozen: state.frozen,
                      moves: state.moves,
                      urgent: state.timeLeft <= 15 && !state.frozen,
                      onPause: () => _pause(context),
                      onBack: () => Navigator.pop(context),
                    ),
                    SetsProgressBar(
                      setsLeft: setsLeft,
                      totalSets: totalSets.clamp(1, 999),
                      accent: const Color(0xFF43A047),
                    ),
                    if (state.banner != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          state.banner!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2E7D32),
                          ),
                        ).animate().fadeIn().scale(
                              begin: const Offset(0.9, 0.9),
                            ),
                      ),
                    Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              Widget board = SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: _CabinetBoard(
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
                                            context
                                                .read<AudioService>()
                                                .playPick();
                                            context.read<GameBloc>().add(
                                                  ItemTapped(pos),
                                                );
                                          },
                                    onMove: state.inputLocked
                                        ? (_, __) {}
                                        : (from, to) {
                                            context
                                                .read<AudioService>()
                                                .playPlace();
                                            context.read<GameBloc>().add(
                                                  ItemMoved(
                                                    from: from,
                                                    to: to,
                                                  ),
                                                );
                                          },
                                  ),
                                ),
                              );
                              if (spice == LevelSpice.framed ||
                                  spice == LevelSpice.bossArena) {
                                board = Container(
                                  margin: const EdgeInsets.all(6),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: spice == LevelSpice.bossArena
                                          ? const Color(0xFFFFD700)
                                          : look.bracket,
                                      width: spice == LevelSpice.bossArena
                                          ? 3.5
                                          : 2.5,
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        look.plank.first.withValues(alpha: 0.35),
                                        look.plank.last.withValues(alpha: 0.15),
                                      ],
                                    ),
                                    boxShadow: spice == LevelSpice.bossArena
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFFFD700)
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 16,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: board,
                                );
                              }
                              if (spice == LevelSpice.spotlight) {
                                board = ShaderMask(
                                  blendMode: BlendMode.dstIn,
                                  shaderCallback: (rect) {
                                    return RadialGradient(
                                      center: const Alignment(0, -0.1),
                                      radius: 1.05,
                                      colors: [
                                        Colors.white,
                                        Colors.white.withValues(alpha: 0.55),
                                      ],
                                    ).createShader(rect);
                                  },
                                  child: board,
                                );
                              }
                              return board;
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
                      _BoosterDock(
                        freezes: progress.progress.hintsRemaining,
                        shuffles: progress.progress.shufflesRemaining,
                        hammers: progress.progress.autoSortRemaining,
                        extras: progress.progress.extraShelfRemaining,
                        accent: look.accent,
                        onPressed: (k) => _booster(context, k, progress),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        );
      },
    );
  }

  String _spiceHint(LevelSpice spice, int setsLeft) {
    final base = 'Sets $setsLeft';
    switch (spice) {
      case LevelSpice.floating:
        return '$base · Floating shelves!';
      case LevelSpice.staggered:
        return '$base · Staggered aisles';
      case LevelSpice.framed:
        return '$base · Cabinet frame';
      case LevelSpice.spotlight:
        return '$base · Spotlight focus';
      case LevelSpice.neonPulse:
        return '$base · Neon Game Den';
      case LevelSpice.bossArena:
        return '$base · 👑 BOSS ARENA';
      case LevelSpice.classic:
        return '$base · Clear the shelves';
    }
  }

  List<Widget> _ambientDecor(ShelfLook look, LevelSpice spice) {
    return [
      Positioned(
        top: 80,
        right: -20,
        child: Text(
          look.moodEmoji,
          style: TextStyle(
            fontSize: 96,
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        left: -10,
        child: Text(
          look.moodEmoji,
          style: TextStyle(
            fontSize: 72,
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      if (look.glitter || spice == LevelSpice.bossArena)
        Positioned(
          top: 120,
          left: 24,
          child: Icon(
            Icons.auto_awesome,
            size: 28,
            color: look.accent.withValues(alpha: 0.35),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.2, end: 0.7, duration: 900.ms),
        ),
    ];
  }
}

/// Irregular Falcon cabinet: rows of shelves with optional gaps (0).
class _CabinetBoard extends StatelessWidget {
  final List<List<int>> layout;
  final List<Shelf> shelves;
  final BoardPos? selected;
  final int clearingShelf;
  final int openingShelf;
  final Set<int> finishedShelves;
  final double scale;
  final ShelfLook look;
  final LevelSpice spice;
  final void Function(BoardPos) onTap;
  final void Function(BoardPos, BoardPos) onMove;

  const _CabinetBoard({
    required this.layout,
    required this.shelves,
    required this.selected,
    required this.clearingShelf,
    required this.openingShelf,
    required this.finishedShelves,
    required this.scale,
    required this.look,
    required this.spice,
    required this.onTap,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final idToIndex = <int, int>{};
    for (var i = 0; i < shelves.length; i++) {
      idToIndex[shelves[i].shelfId] = i;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var r = 0; r < layout.length; r++)
          Padding(
            padding: EdgeInsets.only(
              top: 2,
              bottom: 2,
              left: spice == LevelSpice.staggered && r.isOdd ? 18 : 0,
              right: spice == LevelSpice.staggered && r.isEven ? 18 : 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final cell in layout[r])
                  if (cell == 0)
                    Expanded(child: SizedBox(height: 96 * scale))
                  else
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final idx = idToIndex[cell];
                          if (idx == null) {
                            return SizedBox(height: 96 * scale);
                          }
                          return CabinetShelf(
                            shelf: shelves[idx],
                            shelfIndex: idx,
                            selected: selected,
                            celebrating: clearingShelf == idx,
                            opening: openingShelf == idx,
                            isDone: finishedShelves.contains(idx),
                            scale: scale,
                            look: look,
                            spice: spice,
                            onTap: onTap,
                            onMove: onMove,
                          );
                        },
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GoodsSortHeader extends StatelessWidget {
  final String levelLabel;
  final String time;
  final Color timeColor;
  final bool frozen;
  final int moves;
  final bool urgent;
  final VoidCallback onPause;
  final VoidCallback onBack;

  const _GoodsSortHeader({
    required this.levelLabel,
    required this.time,
    required this.timeColor,
    required this.frozen,
    required this.moves,
    this.urgent = false,
    required this.onPause,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    Widget timer = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: urgent ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: urgent ? AppColors.error : const Color(0xFF66BB6A),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            frozen ? Icons.ac_unit : Icons.timer_outlined,
            color: timeColor,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            time,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: timeColor,
            ),
          ),
        ],
      ),
    );
    if (urgent && !frozen) {
      timer = timer
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textDark,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF43A047),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              levelLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: Center(child: timer)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$moves moves',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onPause,
            icon: const Icon(Icons.pause_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF42A5F5),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _WoodHeader extends StatelessWidget {
  final String levelLabel;
  final String themeLabel;
  final String time;
  final Color timeColor;
  final bool frozen;
  final int stars;
  final int moves;
  final Color accent;
  final bool urgent;
  final VoidCallback onPause;
  final VoidCallback onBack;

  const _WoodHeader({
    required this.levelLabel,
    required this.themeLabel,
    required this.time,
    required this.timeColor,
    required this.frozen,
    required this.stars,
    required this.moves,
    required this.accent,
    this.urgent = false,
    required this.onPause,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    Widget timerPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: frozen
              ? [const Color(0xFFB3E5FC), const Color(0xFF81D4FA)]
              : urgent
                  ? [const Color(0xFFFFCDD2), const Color(0xFFEF9A9A)]
                  : [const Color(0xFFC8E6C9), const Color(0xFFA5D6A7)],
        ),
        border: Border.all(
          color: urgent ? AppColors.error : const Color(0xFF66BB6A),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (urgent ? AppColors.error : const Color(0xFF43A047))
                .withValues(alpha: 0.35),
            blurRadius: urgent ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            frozen ? Icons.ac_unit_rounded : Icons.timer_rounded,
            color: timeColor,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            time,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: timeColor,
              fontSize: 22,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
    if (urgent && !frozen) {
      timerPill = timerPill
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.06, 1.06),
            duration: 600.ms,
          );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 2),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded, size: 22),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF43A047).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  levelLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(child: Center(child: timerPill)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swap_horiz_rounded,
                        size: 16, color: AppColors.textLight),
                    Text(
                      '$moves',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onPause,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF42A5F5).withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.pause_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                themeLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: accent.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 14),
              Text(
                ' Cleared $stars',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  final String hint;
  final List<String> mechanics;
  final Color accent;

  const _ObjectiveCard({
    required this.hint,
    required this.mechanics,
    required this.accent,
  });

  IconData _iconFor(String id) => switch (id) {
        'hidden_back_row' => Icons.layers,
        'moving_bottom_tray' => Icons.swap_horiz,
        'sliding_shelves' => Icons.view_carousel,
        'rotating_tray' => Icons.rotate_right,
        'conveyor_shelf' => Icons.linear_scale,
        'locked_items' => Icons.lock,
        'mystery_boxes' => Icons.inventory_2,
        'stacked_items' => Icons.filter_none,
        'frozen_items' => Icons.ac_unit,
        'moving_divider' => Icons.vertical_split,
        'chain_release' => Icons.auto_awesome,
        _ => Icons.extension,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            ...mechanics.take(3).map(
                  (id) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(_iconFor(id), size: 18, color: accent),
                  ),
                ),
            Expanded(
              child: Text(
                hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComboBar extends StatelessWidget {
  final int combo;
  final double ratio;
  final Color accent;

  const _ComboBar({
    required this.combo,
    required this.ratio,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 0, 56, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 13,
          child: Stack(
            children: [
              Container(color: const Color(0xFF2E3A4A)),
              FractionallySizedBox(
                widthFactor: combo > 0 ? ratio.clamp(0.15, 1.0) : 0.2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(accent, Colors.white, 0.35)!,
                        accent,
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  combo > 0 ? 'Combo x$combo' : 'Match 3 on a shelf to clear',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoosterDock extends StatelessWidget {
  final int freezes;
  final int shuffles;
  final int hammers;
  final int extras;
  final Color accent;
  final void Function(BoosterKind) onPressed;

  const _BoosterDock({
    required this.freezes,
    required this.shuffles,
    required this.hammers,
    required this.extras,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A2A1A), Color(0xFF2A1E12)],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Chip(Icons.undo_rounded, 'Undo', null, const Color(0xFFFFE0B2),
                () => onPressed(BoosterKind.undo)),
            _Chip(Icons.ac_unit_rounded, 'Freeze', freezes,
                const Color(0xFF4FC3F7), () => onPressed(BoosterKind.freeze)),
            _Chip(Icons.shuffle_rounded, 'Refresh', shuffles,
                const Color(0xFFFFB74D), () => onPressed(BoosterKind.shuffle)),
            _Chip(Icons.hardware_rounded, 'Hammer', hammers, accent,
                () => onPressed(BoosterKind.magnet)),
            _Chip(Icons.add_box_rounded, 'Shelf', extras, const Color(0xFF81C784),
                () => onPressed(BoosterKind.extraShelf)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final Color color;
  final VoidCallback onTap;

  const _Chip(this.icon, this.label, this.count, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.35),
                      color.withValues(alpha: 0.12),
                    ],
                  ),
                  border: Border.all(color: color.withValues(alpha: 0.7)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (count != null)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: count! > 0 ? AppColors.primary : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
