import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../data/level_repository.dart';
import '../../providers/progress_provider.dart';
import '../../services/ad_service.dart';
import '../widgets/common_widgets.dart';
import 'gameplay_screen.dart';

class LevelCompleteScreen extends StatefulWidget {
  final int levelId;
  final int stars;
  final int moves;
  final int coins;
  final bool won;
  final int timeLeft;
  final bool daily;
  final String? loseReason;

  const LevelCompleteScreen({
    super.key,
    required this.levelId,
    required this.stars,
    required this.moves,
    required this.coins,
    required this.won,
    this.timeLeft = 0,
    this.daily = false,
    this.loseReason,
  });

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen> {
  late final ConfettiController _confetti;
  int _shownCoins = 0;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.won) {
        _confetti.play();
        _animateCoins();
      }
    });
  }

  Future<void> _animateCoins() async {
    for (var i = 0; i <= widget.coins; i += 2) {
      if (!mounted) return;
      setState(() => _shownCoins = i.clamp(0, widget.coins));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    setState(() => _shownCoins = widget.coins);
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final next = widget.levelId + 1;
    final hasNext = widget.won &&
        !widget.daily &&
        next <= LevelRepository.instance.totalLevels;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.won
                ? const [Color(0xFFFFF8F0), Color(0xFFFFE0B2)]
                : const [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (widget.won)
              ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.accent,
                  AppColors.success,
                ],
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    MiaAvatar(
                      size: 96,
                      mood: widget.won ? 'celebrating' : 'thinking',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.won
                          ? (widget.daily
                              ? 'Challenge Cleared!'
                              : 'Level Complete!')
                          : 'Almost!',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2),
                    if (!widget.won && widget.loseReason != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          widget.loseReason!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (widget.won)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final earned = i < widget.stars;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              earned
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 56,
                              color: earned
                                  ? AppColors.secondary
                                  : AppColors.textLight,
                            )
                                .animate(delay: (200 * i).ms)
                                .scale(begin: const Offset(0.2, 0.2))
                                .fadeIn(),
                          );
                        }),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      widget.won
                          ? 'Time left: ${widget.timeLeft}s • Moves: ${widget.moves}'
                          : 'Try again — match 3 identical goods to clear space!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                      ),
                    ),
                    if (widget.won) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '+$_shownCoins',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    if (widget.won)
                      TextButton(
                        onPressed: () async {
                          final ok = await context
                              .read<ProgressProvider>()
                              .watchAdForTool(RewardType.doubleCoins);
                          if (ok && mounted) {
                            await context
                                .read<ProgressProvider>()
                                .addCoins(widget.coins);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('2x coins claimed!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Text('Watch ad for 2x coins'),
                      ),
                    if (hasNext)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) =>
                                    GameplayScreen(levelId: next),
                              ),
                            );
                          },
                          child: const Text('Next Level'),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => GameplayScreen(
                                levelId: widget.levelId,
                                daily: widget.daily,
                              ),
                            ),
                          );
                        },
                        child: Text(widget.won ? 'Replay' : 'Try Again'),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      child: const Text('Map'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
