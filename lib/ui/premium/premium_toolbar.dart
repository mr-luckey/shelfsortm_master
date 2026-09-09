import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/audio_cubit.dart';
import '../../providers/progress_provider.dart';
import 'premium_tokens.dart';

/// Freeze + Hint — compact pair beside the goal panel (bottom stays free for ads).
class PremiumBoosterRail extends StatelessWidget {
  final int freezeCount;
  final int hintCount;
  final VoidCallback? onFreeze;
  final VoidCallback? onHint;

  const PremiumBoosterRail({
    super.key,
    this.freezeCount = 0,
    this.hintCount = 0,
    this.onFreeze,
    this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _BoosterBtn(
          icon: Icons.ac_unit_rounded,
          color: PremiumTokens.freezeGreen,
          count: freezeCount,
          label: 'FREEZE',
          cost: ProgressProvider.freezeCoinCost,
          costAsset: '${PremiumTokens.uiRoot}/coin.webp',
          costFallbackIcon: Icons.monetization_on,
          costColor: PremiumTokens.coinGold,
          onTap: onFreeze ?? () {},
        ),
        SizedBox(width: 6.w),
        _BoosterBtn(
          icon: Icons.lightbulb_rounded,
          color: PremiumTokens.hintOrange,
          count: hintCount,
          label: 'HINT',
          cost: ProgressProvider.hintGemCost,
          costAsset: '${PremiumTokens.uiRoot}/gem.webp',
          costFallbackIcon: Icons.diamond,
          costColor: PremiumTokens.gemMagenta,
          onTap: onHint ?? () {},
        ),
      ],
    );
  }
}

class _BoosterBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;
  final int cost;
  final String costAsset;
  final IconData costFallbackIcon;
  final Color costColor;
  final VoidCallback onTap;

  const _BoosterBtn({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
    required this.cost,
    required this.costAsset,
    required this.costFallbackIcon,
    required this.costColor,
    required this.onTap,
  });

  @override
  State<_BoosterBtn> createState() => _BoosterBtnState();
}

class _BoosterBtnState extends State<_BoosterBtn> {
  late final _PressScaleCubit _scaleCubit;

  @override
  void initState() {
    super.initState();
    _scaleCubit = _PressScaleCubit();
  }

  @override
  void dispose() {
    _scaleCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _scaleCubit,
      child: BlocBuilder<_PressScaleCubit, double>(
        builder: (context, scale) {
          return GestureDetector(
            onTapDown: (_) => context.read<_PressScaleCubit>().down(0.94),
            onTapUp: (_) {
              context.read<_PressScaleCubit>().up();
              try {
                context.read<AudioCubit>().playButton();
              } catch (_) {
                HapticFeedback.selectionClick();
              }
              widget.onTap();
            },
            onTapCancel: () => context.read<_PressScaleCubit>().up(),
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 120),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        widget.costAsset,
                        width: 12.w,
                        height: 12.w,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          widget.costFallbackIcon,
                          color: widget.costColor,
                          size: 12.sp,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${widget.cost}',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          fontSize: 10.sp,
                          color: Colors.white,
                          height: 1,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.lerp(widget.color, Colors.white, 0.25)!,
                              widget.color,
                              Color.lerp(widget.color, Colors.black, 0.15)!,
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFFE8C9A0),
                            width: 1.5.w,
                          ),
                          boxShadow: PremiumTokens.glossyShadow(
                            y: 3.h,
                            blur: 6.h,
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
                      Positioned(
                        right: -4.w,
                        top: -4.h,
                        child: Container(
                          constraints: BoxConstraints(minWidth: 18.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: PremiumTokens.badgeRed,
                            borderRadius: BorderRadius.circular(9.r),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.4.w,
                            ),
                          ),
                          child: Text(
                            '${widget.count}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 9.sp,
                            ),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.1, 1.1),
                              duration: 900.ms,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    widget.label,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 8.sp,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PressScaleCubit extends Cubit<double> {
  _PressScaleCubit() : super(1);
  void down(double scale) => emit(scale);
  void up() => emit(1);
}
