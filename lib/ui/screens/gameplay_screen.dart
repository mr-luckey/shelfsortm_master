import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../bloc/game_bloc.dart';
import '../../bloc/game_event.dart';
import '../../bloc/game_state.dart';
import '../../data/level_repository.dart';
import '../../engine/match_engine.dart';
import '../../providers/progress_provider.dart';
import '../../services/ad_service.dart';
import '../../services/save_service.dart';
import '../widgets/pixel_shelf.dart';
import 'level_complete_screen.dart';

/// Sort Challenge gameplay — BLoC only, cabinet shelves, no belt.
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

class _View extends StatelessWidget {
  final int levelId;
  final bool daily;

  const _View({required this.levelId, required this.daily});

  String _fmt(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paused',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
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
              child: const Text('Exit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish(BuildContext context, GameState state) async {
    final progress = context.read<ProgressProvider>();
    await context.read<SaveService>().clearMidLevel();
    final stars = state.stars;
    final coins = stars * 10 + state.matches * 2;
    if (daily) {
      await progress.completeDailyChallenge(coins: 80 + coins);
    } else if (state.status == GameStatus.won) {
      await progress.completeLevel(
        levelId: levelId,
        stars: stars,
        moves: state.moves,
        coinsEarned: coins,
      );
    }
    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, b) => LevelCompleteScreen(
          levelId: levelId,
          stars: stars,
          moves: state.moves,
          coins: coins,
          won: state.status == GameStatus.won,
          timeLeft: state.timeLeft,
          daily: daily,
          loseReason: state.status == GameStatus.lostTime
              ? 'Time is up!'
              : state.status == GameStatus.lostSpace
                  ? 'No space left!'
                  : null,
        ),
        transitionsBuilder: (_, anim, __, child) =>
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
          'Shuffle',
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
          'Magnet',
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
      listenWhen: (p, c) => !p.isTerminal && c.isTerminal,
      listener: (context, state) => _finish(context, state),
      builder: (context, state) {
        if (!state.ready) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final progress = context.watch<ProgressProvider>();
        final buffers = state.level?.bufferShelves ?? 2;
        final bufferStart = state.shelves.length - buffers;
        final timeColor = state.timeLeft <= 15
            ? AppColors.error
            : state.frozen
                ? const Color(0xFF29B6F6)
                : AppColors.textDark;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.themeGradient(
                state.level?.themeRoom ?? 'kitchen',
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _Hud(
                    title: daily ? 'Daily' : 'Level ${state.level?.levelId}',
                    subtitle:
                        'Sort 3 matching goods on a shelf • ${state.itemCount} left',
                    time: _fmt(state.timeLeft),
                    timeColor: timeColor,
                    frozen: state.frozen,
                    onBack: () => Navigator.pop(context),
                    onPause: () => _pause(context),
                  ),
                  if (state.banner != null)
                    Text(
                      state.banner!,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    )
                        .animate()
                        .fadeIn()
                        .scale(begin: const Offset(0.85, 0.85)),
                  _Boosters(
                    freezes: progress.progress.hintsRemaining,
                    shuffles: progress.progress.shufflesRemaining,
                    magnets: progress.progress.autoSortRemaining,
                    extras: progress.progress.extraShelfRemaining,
                    onPressed: (k) => _booster(context, k, progress),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'Tap a good, then tap an empty slot — or drag it',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.white.withValues(alpha: 0.35),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        itemCount: state.shelves.length,
                        itemBuilder: (context, i) {
                          return CabinetShelf(
                            shelf: state.shelves[i],
                            shelfIndex: i,
                            selected: state.selected,
                            celebrating: state.clearingShelf == i,
                            isBuffer: i >= bufferStart &&
                                !state.shelves[i].isTemporary,
                            onTap: (pos) => context
                                .read<GameBloc>()
                                .add(ItemTapped(pos)),
                            onMove: (from, to) => context
                                .read<GameBloc>()
                                .add(ItemMoved(from: from, to: to)),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Hud extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final Color timeColor;
  final bool frozen;
  final VoidCallback onBack;
  final VoidCallback onPause;

  const _Hud({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.timeColor,
    required this.frozen,
    required this.onBack,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: timeColor, width: 2.5),
            ),
            child: Row(
              children: [
                Icon(
                  frozen ? Icons.ac_unit_rounded : Icons.timer_rounded,
                  color: timeColor,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: timeColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onPause,
            icon: const Icon(Icons.pause_circle_filled_rounded),
            color: AppColors.primary,
            iconSize: 32,
          ),
        ],
      ),
    );
  }
}

class _Boosters extends StatelessWidget {
  final int freezes;
  final int shuffles;
  final int magnets;
  final int extras;
  final void Function(BoosterKind) onPressed;

  const _Boosters({
    required this.freezes,
    required this.shuffles,
    required this.magnets,
    required this.extras,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Chip(
            Icons.undo_rounded,
            'Undo',
            null,
            AppColors.textDark,
            () => onPressed(BoosterKind.undo),
          ),
          _Chip(
            Icons.ac_unit_rounded,
            'Freeze',
            freezes,
            const Color(0xFF29B6F6),
            () => onPressed(BoosterKind.freeze),
          ),
          _Chip(
            Icons.shuffle_rounded,
            'Refresh',
            shuffles,
            AppColors.primary,
            () => onPressed(BoosterKind.shuffle),
          ),
          _Chip(
            Icons.auto_awesome_rounded,
            'Magnet',
            magnets,
            AppColors.accent,
            () => onPressed(BoosterKind.magnet),
          ),
          _Chip(
            Icons.add_box_rounded,
            'Shelf',
            extras,
            AppColors.success,
            () => onPressed(BoosterKind.extraShelf),
          ),
        ],
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
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 22),
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
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
