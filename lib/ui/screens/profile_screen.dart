import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/iap_service.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProgressProvider, SettingsProvider>(
      builder: (context, progress, settings, _) {
        final p = progress.progress;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.background, Color(0xFFFFE8D6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const MiaAvatar(size: 88, mood: 'happy'),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    p.playerName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: CurrencyHud(coins: p.coins, gems: p.gems),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Stars: ${p.totalStars}  •  Level ${p.currentLevel}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SwitchListTile(
                  title: const Text('Sound Effects'),
                  value: settings.sfx,
                  activeThumbColor: AppColors.primary,
                  onChanged: settings.setSfx,
                ),
                SwitchListTile(
                  title: const Text('Music'),
                  value: settings.music,
                  activeThumbColor: AppColors.primary,
                  onChanged: settings.setMusic,
                ),
                SwitchListTile(
                  title: const Text('ASMR Mode'),
                  subtitle: const Text('Richer haptics & louder feedback'),
                  value: settings.asmr,
                  activeThumbColor: AppColors.accent,
                  onChanged: settings.setAsmr,
                ),
                SwitchListTile(
                  title: const Text('Haptics'),
                  value: settings.haptics,
                  activeThumbColor: AppColors.primary,
                  onChanged: settings.setHaptics,
                ),
                ListTile(
                  title: const Text('Restore Purchases'),
                  trailing: const Icon(Icons.restore),
                  onTap: () async {
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
                  title: const Text('Privacy Policy'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Privacy Policy'),
                        content: const Text(
                          'ShelfSort Master stores progress locally. '
                          'No PII is collected beyond Play Store requirements. '
                          'Ads/IAP use Google services when enabled.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const ListTile(
                  title: Text('Version'),
                  trailing: Text('1.0.0+1'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
