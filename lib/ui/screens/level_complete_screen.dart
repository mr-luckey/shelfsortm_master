import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/level_repository.dart';
import '../../providers/progress_provider.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';
import '../meta/meta_chrome.dart';
import '../premium/premium_gameplay_screen.dart';
import '../premium/premium_tokens.dart';
import '../widgets/common_widgets.dart';

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
  late final _CoinsCubit _coinsCubit;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _coinsCubit = _CoinsCubit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audio = context.read<AudioService>();
      audio.startMusic();
      if (widget.won) {
        audio.playWhoosh();
        _confetti.play();
        _animateCoins();
      } else {
        audio.playInvalid();
      }
    });
  }

  Future<void> _animateCoins() async {
    for (var i = 0; i <= widget.coins; i += 2) {
      if (!mounted) return;
      _coinsCubit.show(i.clamp(0, widget.coins));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    _coinsCubit.show(widget.coins);
  }

  @override
  void dispose() {
    _coinsCubit.close();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final next = widget.levelId + 1;
    final hasNext = widget.won &&
        !widget.daily &&
        next <= LevelRepository.instance.totalLevels;

    return BlocProvider.value(
      value: _coinsCubit,
      child: Scaffold(
        body: MetaBackdrop(
          child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (widget.won)
              ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  MetaChrome.gold,
                  Color(0xFF81C784),
                  Color(0xFFFFB74D),
                  Colors.white,
                ],
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    MiaAvatar(
                      size: 96,
                      mood: widget.won ? 'celebrating' : 'thinking',
                    ),
                    const SizedBox(height: 14),
                    MetaTitle(
                      widget.won
                          ? (widget.daily
                              ? 'Challenge Cleared!'
                              : 'Level Complete!')
                          : 'Almost!',
                      size: 28,
                    ).animate().fadeIn().slideY(begin: 0.15),
                    if (!widget.won && widget.loseReason != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          widget.loseReason!,
                          style: GoogleFonts.nunito(
                            color: const Color(0xFFFF8A80),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (widget.won)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final earned = i < widget.stars;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: earned
                                ? Image.asset(
                                    MetaChrome.starBadgeAsset,
                                    width: 52,
                                    height: 52,
                                    errorBuilder: (context, error, stack) =>
                                        const Icon(
                                      Icons.star_rounded,
                                      size: 52,
                                      color: MetaChrome.gold,
                                    ),
                                  )
                                : Icon(
                                    Icons.star_outline_rounded,
                                    size: 52,
                                    color: MetaChrome.cream.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                          )
                              .animate(delay: (180 * i).ms)
                              .scale(begin: const Offset(0.2, 0.2))
                              .fadeIn();
                        }),
                      ),
                    const SizedBox(height: 12),
                    MetaWoodCard(
                      child: Column(
                        children: [
                          Text(
                            widget.won
                                ? 'Time left: ${widget.timeLeft}s  •  Moves: ${widget.moves}'
                                : 'Match 3 identical goods to clear space!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              color: MetaChrome.cream.withValues(alpha: 0.85),
                            ),
                          ),
                          if (widget.won) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  '${PremiumTokens.uiRoot}/coin.png',
                                  width: 26,
                                  height: 26,
                                  errorBuilder: (context, error, stack) =>
                                      const Icon(
                                    Icons.monetization_on,
                                    color: MetaChrome.gold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                BlocBuilder<_CoinsCubit, int>(
                                  builder: (context, shownCoins) {
                                    return Text(
                                      '+$shownCoins',
                                      style: GoogleFonts.nunito(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: MetaChrome.gold,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
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
                        child: Text(
                          'Watch ad for 2x coins',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            color: MetaChrome.gold,
                          ),
                        ),
                      ),
                    if (hasNext)
                      MetaPrimaryButton(
                        label: 'Next Level',
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PremiumGameplayScreen(levelId: next),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 10),
                    MetaSecondaryButton(
                      label: widget.won ? 'Replay' : 'Try Again',
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => PremiumGameplayScreen(
                              levelId: widget.levelId,
                              daily: widget.daily,
                            ),
                          ),
                        );
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<AudioService>().playButton();
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      child: Text(
                        'Home',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          color: MetaChrome.cream,
                        ),
                      ),
                    ),
                  ],
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

class _CoinsCubit extends Cubit<int> {
  _CoinsCubit() : super(0);
  void show(int value) => emit(value);
}
