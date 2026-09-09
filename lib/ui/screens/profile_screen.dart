import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../bloc/audio_cubit.dart';
import '../meta/meta_chrome.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProgressProvider, SettingsProvider>(
      builder: (context, progress, settings, _) {
        final p = progress.progress;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: MetaBackdrop(
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Material(
                      type: MaterialType.transparency,
                      child: ListView(
                        padding: EdgeInsets.all(20.w),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () {
                                context.read<AudioCubit>().playButton();
                                Navigator.of(context).maybePop();
                              },
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: MetaChrome.cream,
                              ),
                            ),
                          ),
                          const Center(child: AppLogo(size: 120))
                              .animate()
                              .fadeIn()
                              .scale(begin: const Offset(0.9, 0.9)),
                          SizedBox(height: 12.h),
                          Center(
                            child: Text(
                              p.playerName,
                              style: GoogleFonts.nunito(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w900,
                                color: MetaChrome.cream,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Center(
                              child: CurrencyHud(coins: p.coins, gems: p.gems)),
                          SizedBox(height: 8.h),
                          Center(
                            child: Text(
                              'Stars: ${p.totalStars}  •  Level ${p.currentLevel}',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700,
                                color:
                                    MetaChrome.cream.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          MetaWoodCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Settings',
                                  style: GoogleFonts.nunito(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w900,
                                    color: MetaChrome.gold,
                                  ),
                                ),
                                _toggle(
                                  'Sound Effects',
                                  settings.sfx,
                                  settings.setSfx,
                                ),
                                _toggle(
                                    'Music', settings.music, settings.setMusic),
                                _toggle(
                                  'ASMR Mode',
                                  settings.asmr,
                                  settings.setAsmr,
                                  subtitle:
                                      'Richer haptics & louder feedback',
                                ),
                                _toggle(
                                  'Haptics',
                                  settings.haptics,
                                  settings.setHaptics,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const AdBannerWidget(placement: 'profile'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _toggle(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    String? subtitle,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          color: MetaChrome.cream,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: GoogleFonts.nunito(
                fontSize: 12.sp,
                color: MetaChrome.cream.withValues(alpha: 0.7),
              ),
            ),
      value: value,
      activeThumbColor: MetaChrome.gold,
      activeTrackColor: MetaChrome.brass.withValues(alpha: 0.5),
      onChanged: onChanged,
    );
  }
}
