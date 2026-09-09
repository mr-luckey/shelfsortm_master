import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/theme/goods_sort_theme.dart';
import '../../bloc/audio_cubit.dart';
import '../../services/ad_service.dart';
import '../meta/praise_burst.dart';
import '../premium/premium_tokens.dart';

/// Pixel specs from Goods Sort™ gameplay screenshots (Play Store).
abstract final class GoodsSortLayout {
  static const bgTop = Color(0xFFF7EED8);
  static const bgBottom = Color(0xFFE8D5B5);
  static const cabinetFrame = Color(0xFF5D4037);
  static const boosterBar = Color(0xFF3E2723);

  static double get headerHeight => 56.h;
  static double get progressHeight => 8.h;
  static double get boosterBarHeight => 76.h;
  static double get shelfRowHeight => 100.h;
  static double get plankHeight => 12.h;
  static double get itemSizeOnShelf => 56.w;

  static BoxDecoration get screenBg => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ),
        image: DecorationImage(
          image: AssetImage('assets/images/rooms/gameplay_room_bg.png'),
          fit: BoxFit.cover,
        ),
      );
}

class GoodsSortTopBar extends StatelessWidget {
  final String levelText;
  final String timeText;
  final bool urgent;
  final bool frozen;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  const GoodsSortTopBar({
    super.key,
    required this.levelText,
    required this.timeText,
    required this.onBack,
    required this.onSettings,
    this.urgent = false,
    this.frozen = false,
  });

  @override
  Widget build(BuildContext context) {
    final timerBg = urgent
        ? const Color(0xFFFFCDD2)
        : frozen
            ? const Color(0xFFB3E5FC)
            : const Color(0xFFC8E6C9);
    final timerBorder = urgent
        ? const Color(0xFFE53935)
        : frozen
            ? const Color(0xFF0288D1)
            : GoodsSortTheme.playGreen;

    return SizedBox(
      height: GoodsSortLayout.headerHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Row(
          children: [
            _RoundIconButton(
              icon: Icons.settings_rounded,
              onTap: onSettings,
              bg: Colors.white.withValues(alpha: 0.95),
              iconColor: GoodsSortLayout.cabinetFrame,
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
              decoration: BoxDecoration(
                gradient: GoodsSortTheme.playGradient,
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: GoodsSortTheme.playGreen.withValues(alpha: 0.35),
                    blurRadius: 6.h,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Text(
                levelText,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14.sp,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: timerBg,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: timerBorder, width: 2.w),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    frozen ? Icons.ac_unit : Icons.timer_outlined,
                    size: 18.sp,
                    color: GoodsSortLayout.cabinetFrame,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18.sp,
                      color: const Color(0xFF3E2723),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 6.w),
            _RoundIconButton(
              icon: Icons.home_rounded,
              onTap: onBack,
              bg: Colors.white.withValues(alpha: 0.95),
              iconColor: GoodsSortLayout.cabinetFrame,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  final Color iconColor;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.bg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40.w,
          height: 40.w,
          child: Icon(icon, size: 22.sp, color: iconColor),
        ),
      ),
    );
  }
}

class GoodsSortProgressBar extends StatelessWidget {
  final double ratio;

  const GoodsSortProgressBar({super.key, required this.ratio});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 6.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99.r),
        child: SizedBox(
          height: GoodsSortLayout.progressHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black.withValues(alpha: 0.12)),
              FractionallySizedBox(
                widthFactor: ratio.clamp(0.02, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        GoodsSortTheme.playGreenLight,
                        GoodsSortTheme.playGreen,
                      ],
                    ),
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

class GoodsSortBoosterBar extends StatelessWidget {
  final int freezes;
  final int shuffles;
  final int hammers;
  final int extras;
  final void Function(String id) onPressed;

  const GoodsSortBoosterBar({
    super.key,
    required this.freezes,
    required this.shuffles,
    required this.hammers,
    required this.extras,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GoodsSortLayout.boosterBarHeight,
      margin: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: GoodsSortLayout.boosterBar,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF6D4C41), width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10.h,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BoosterBtn(
            icon: Icons.undo_rounded,
            count: null,
            color: const Color(0xFFFFCC80),
            onTap: () => onPressed('undo'),
          ),
          _BoosterBtn(
            icon: Icons.ac_unit_rounded,
            count: freezes,
            color: const Color(0xFF81D4FA),
            onTap: () => onPressed('freeze'),
          ),
          _BoosterBtn(
            icon: Icons.shuffle_rounded,
            count: shuffles,
            color: const Color(0xFFFFAB91),
            onTap: () => onPressed('shuffle'),
          ),
          _BoosterBtn(
            icon: Icons.hardware_rounded,
            count: hammers,
            color: const Color(0xFFCE93D8),
            onTap: () => onPressed('hammer'),
          ),
          _BoosterBtn(
            icon: Icons.add_box_rounded,
            count: extras,
            color: const Color(0xFFA5D6A7),
            onTap: () => onPressed('shelf'),
          ),
        ],
      ),
    );
  }
}

class _BoosterBtn extends StatelessWidget {
  final IconData icon;
  final int? count;
  final Color color;
  final VoidCallback onTap;

  const _BoosterBtn({
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.22),
              border: Border.all(
                color: color.withValues(alpha: 0.85),
                width: 2.w,
              ),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          if (count != null)
            Positioned(
              right: -2.w,
              top: -2.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: count! > 0 ? GoodsSortTheme.playGreen : Colors.grey,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.white, width: 1.2.w),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GoodsSortPauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;
  final VoidCallback? onHome;
  final VoidCallback? onSettings;

  const GoodsSortPauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
    this.onHome,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.62),
      child: MetaPopupScope(
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 18.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5A3418), Color(0xFF2A1608)],
            ),
            border: Border.all(color: const Color(0xFFE8C45A), width: 1.8.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 24.h,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2A1608),
                  border: Border.all(
                    color: const Color(0xFFE8C45A),
                    width: 1.5.w,
                  ),
                ),
                child: Icon(
                  Icons.pause_rounded,
                  color: const Color(0xFFE8C45A),
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Paused',
                style: GoogleFonts.fredoka(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF7E6C8),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Take a breath — shelves can wait',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                  color: const Color(0xFFF7E6C8).withValues(alpha: 0.75),
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    elevation: 6,
                    side: BorderSide(
                      color: const Color(0xFFE8C45A),
                      width: 1.4.w,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed: () {
                    try {
                      context.read<AudioCubit>().playButton();
                    } catch (_) {}
                    onResume();
                  },
                  child: Text(
                    'Continue',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 17.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              _PauseAction(
                icon: Icons.refresh_rounded,
                label: 'Restart',
                onTap: onRestart,
              ),
              if (onSettings != null)
                _PauseAction(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: onSettings!,
                ),
              _PauseAction(
                icon: Icons.home_rounded,
                label: 'Home',
                onTap: onHome ?? onQuit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PauseAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: () {
            try {
              context.read<AudioCubit>().playButton();
            } catch (_) {}
            onTap();
          },
          icon: Icon(icon, color: const Color(0xFFE8C45A), size: 20.sp),
          label: Text(
            label,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              fontSize: 15.sp,
              color: const Color(0xFFF7E6C8),
            ),
          ),
        ),
      ),
    );
  }
}

class GoodsSortLoseOverlay extends StatelessWidget {
  final bool isTime;
  final VoidCallback onWatchAd;
  final VoidCallback onQuit;

  const GoodsSortLoseOverlay({
    super.key,
    required this.isTime,
    required this.onWatchAd,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    final adsOnline = context.watch<AdService>().adsUiEnabled;
    return Container(
      color: Colors.black54,
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 360.w),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTime ? "Time's Up!" : 'No Space Left!',
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900),
              ),
              if (adsOnline) ...[
                SizedBox(height: 12.h),
                Image.asset(
                  '${PremiumTokens.uiRoot}/gift_box.png',
                  width: 72.w,
                  height: 72.w,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
                SizedBox(height: 8.h),
                Text(
                  isTime
                      ? '+60 seconds to keep sorting'
                      : 'Add a shelf to continue',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF757575)),
                ),
              ],
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        try {
                          context.read<AudioCubit>().playButton();
                        } catch (_) {}
                        onQuit();
                      },
                      child: const Text('Quit'),
                    ),
                  ),
                  if (adsOnline) ...[
                    SizedBox(width: 10.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GoodsSortTheme.playGreen,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          try {
                            context.read<AudioCubit>().playButton();
                          } catch (_) {}
                          onWatchAd();
                        },
                        child: const Text('Watch Ad'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoodsSortCupboard extends StatelessWidget {
  final Widget child;

  const GoodsSortCupboard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7D5A48),
            Color(0xFF5D4037),
            Color(0xFF4E342E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14.h,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: ClipRRect(
        clipBehavior: Clip.none,
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          children: [
            // Crown molding
            Container(
              height: 16.h,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF8D6E63),
                    Color(0xFF6D4C41),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  height: 4.h,
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF8EDD8),
                      Color(0xFFEED9B8),
                      Color(0xFFE2C9A0),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF8D6E63).withValues(alpha: 0.55),
                    width: 2.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 6.h,
                      offset: Offset(0, 3.h),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  clipBehavior: Clip.none,
                  borderRadius: BorderRadius.circular(8.r),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// @deprecated Use [GoodsSortCupboard]
class GoodsSortCabinetFrame extends StatelessWidget {
  final Widget child;

  const GoodsSortCabinetFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) => GoodsSortCupboard(child: child);
}
