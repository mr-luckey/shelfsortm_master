import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../bloc/audio_cubit.dart';
import '../../services/iap_service.dart';
import '../meta/meta_chrome.dart';
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
              child: Material(
                type: MaterialType.transparency,
                child: ListView(
                  padding: const EdgeInsets.all(20),
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
                    const MiaAvatar(size: 88, mood: 'happy')
                        .animate()
                        .fadeIn()
                        .scale(begin: const Offset(0.9, 0.9)),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        p.playerName,
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: MetaChrome.cream,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(child: CurrencyHud(coins: p.coins, gems: p.gems)),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Stars: ${p.totalStars}  •  Level ${p.currentLevel}',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: MetaChrome.cream.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    MetaWoodCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: MetaChrome.gold,
                            ),
                          ),
                          _toggle(
                            'Sound Effects',
                            settings.sfx,
                            settings.setSfx,
                          ),
                          _toggle('Music', settings.music, settings.setMusic),
                          _toggle(
                            'ASMR Mode',
                            settings.asmr,
                            settings.setAsmr,
                            subtitle: 'Richer haptics & louder feedback',
                          ),
                          _toggle(
                            'Haptics',
                            settings.haptics,
                            settings.setHaptics,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    MetaWoodCard(
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Restore Purchases',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800,
                                color: MetaChrome.cream,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.restore,
                              color: MetaChrome.gold,
                            ),
                            onTap: () async {
                              context.read<AudioCubit>().playButton();
                              await IapService().restorePurchases();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Purchases restored (stub)'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Privacy Policy',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800,
                                color: MetaChrome.cream,
                              ),
                            ),
                            onTap: () {
                              context.read<AudioCubit>().playButton();
                              showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  backgroundColor: const Color(0xFF3A2410),
                                  title: Text(
                                    'Privacy Policy',
                                    style: GoogleFonts.nunito(
                                      color: MetaChrome.cream,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  content: Text(
                                    'ShelfSort Master stores progress locally. '
                                    'No PII is collected beyond Play Store requirements. '
                                    'Ads/IAP use Google services when enabled.',
                                    style: GoogleFonts.nunito(
                                      color: MetaChrome.cream,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c),
                                      child: const Text(
                                        'OK',
                                        style: TextStyle(color: MetaChrome.gold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Version',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800,
                                color: MetaChrome.cream,
                              ),
                            ),
                            trailing: Text(
                              '1.0.0+1',
                              style: GoogleFonts.nunito(
                                color: MetaChrome.gold,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                fontSize: 12,
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
