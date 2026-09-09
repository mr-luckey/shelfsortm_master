import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../bloc/audio_cubit.dart';
import '../../data/level_repository.dart';
import '../../providers/progress_provider.dart';
import '../../services/ad_service.dart';
import '../meta/meta_chrome.dart';
import '../premium/premium_gameplay_screen.dart';
import '../premium/premium_tokens.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/gift_box_fab.dart';
import '../../services/gift_loot.dart';

class LevelCompleteScreen extends StatefulWidget {
  final int levelId;
  final int stars;
  final int moves;
  final int coins;
  final int gems;
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
    this.gems = 0,
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
      final audio = context.read<AudioCubit>();
      final ads = context.read<AdService>();
      audio.startMusic();
      ads.preloadInterstitial(placement: 'after_level');
      if (widget.won) {
        ads.preloadRewarded(placement: 'gift_box');
        audio.playWhoosh();
        _confetti.play();
        _animateCoins();
      } else {
        audio.playInvalid();
      }
    });
  }

  Future<void> _leaveWithInterstitial(VoidCallback navigate) async {
    final ads = context.read<AdService>();
    if (ads.adsUiEnabled && !ads.isFullScreenShowing) {
      await ads.showInterstitial(placement: 'after_level');
    }
    if (!mounted) return;
    navigate();
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
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    SizedBox(height: 12.h),
                    _CompletedLevelBadge(levelId: widget.levelId),
                    SizedBox(height: 14.h),
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
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(
                          widget.loseReason!,
                          style: GoogleFonts.nunito(
                            color: const Color(0xFFFF8A80),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    SizedBox(height: 16.h),
                    if (widget.won)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final earned = i < widget.stars;
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.w),
                            child: earned
                                ? Image.asset(
                                    MetaChrome.starBadgeAsset,
                                    width: 52.w,
                                    height: 52.w,
                                    errorBuilder: (context, error, stack) =>
                                        Icon(
                                      Icons.star_rounded,
                                      size: 52.sp,
                                      color: MetaChrome.gold,
                                    ),
                                  )
                                : Icon(
                                    Icons.star_outline_rounded,
                                    size: 52.sp,
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
                    SizedBox(height: 12.h),
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
                            SizedBox(height: 10.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  '${PremiumTokens.uiRoot}/coin.webp',
                                  width: 26.w,
                                  height: 26.w,
                                  errorBuilder: (context, error, stack) =>
                                      const Icon(
                                    Icons.monetization_on,
                                    color: MetaChrome.gold,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                BlocBuilder<_CoinsCubit, int>(
                                  builder: (context, shownCoins) {
                                    return Text(
                                      '+$shownCoins',
                                      style: GoogleFonts.nunito(
                                        fontSize: 28.sp,
                                        fontWeight: FontWeight.w900,
                                        color: MetaChrome.gold,
                                      ),
                                    );
                                  },
                                ),
                                if (widget.gems > 0) ...[
                                  SizedBox(width: 18.w),
                                  Image.asset(
                                    '${PremiumTokens.uiRoot}/gem.webp',
                                    width: 26.w,
                                    height: 26.w,
                                    errorBuilder: (context, error, stack) =>
                                        const Icon(
                                      Icons.diamond,
                                      color: PremiumTokens.gemMagenta,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    '+${widget.gems}',
                                    style: GoogleFonts.nunito(
                                      fontSize: 28.sp,
                                      fontWeight: FontWeight.w900,
                                      color: PremiumTokens.gemMagenta,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (widget.won)
                      Column(
                        children: [
                          GiftBoxFab(
                            size: 72,
                            pool: GiftLootPool.doubleCoins,
                            onLoot: (loot) async {
                              if (loot is! DoubleCoinsLoot) return;
                              final progress = context.read<ProgressProvider>();
                              await progress.addCoins(widget.coins);
                            },
                          ),
                          SizedBox(height: 4.h),
                          Consumer2<AdService, ProgressProvider>(
                            builder: (context, ads, progress, _) {
                              if (!ads.adsUiEnabled ||
                                  progress.progress.removeAds) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                'Tap twice for 2x coins',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w800,
                                  color: MetaChrome.gold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    if (hasNext)
                      MetaPrimaryButton(
                        label: 'Next Level',
                        onPressed: () {
                          _leaveWithInterstitial(() {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PremiumGameplayScreen(levelId: next),
                              ),
                            );
                          });
                        },
                      ),
                    SizedBox(height: 10.h),
                    MetaSecondaryButton(
                      label: widget.won ? 'Replay' : 'Try Again',
                      onPressed: () {
                        _leaveWithInterstitial(() {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => PremiumGameplayScreen(
                                levelId: widget.levelId,
                                daily: widget.daily,
                              ),
                            ),
                          );
                        });
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<AudioCubit>().playButton();
                        _leaveWithInterstitial(() {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        });
                      },
                      child: Text(
                        'Home',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          color: MetaChrome.cream,
                        ),
                      ),
                    ),
                    const AdBannerWidget(placement: 'result'),
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

class _CompletedLevelBadge extends StatelessWidget {
  final int levelId;

  const _CompletedLevelBadge({required this.levelId});

  @override
  Widget build(BuildContext context) {
    final w = 96.w;
    final h = 110.h;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            '${PremiumTokens.uiRoot}/level_shield.png',
            width: w,
            height: h,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          Padding(
            padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'LEVEL',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.sp,
                    letterSpacing: 0.6,
                    height: 1,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 2),
                    ],
                  ),
                ),
                Text(
                  '$levelId',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28.sp,
                    height: 1,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinsCubit extends Cubit<int> {
  _CoinsCubit() : super(0);
  void show(int value) => emit(value);
}
