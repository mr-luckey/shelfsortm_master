import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../bloc/audio_cubit.dart';
import '../../services/analytics_service.dart';
import '../../services/local_notification_service.dart';
import '../meta/meta_chrome.dart';
import '../widgets/common_widgets.dart';
import 'home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AudioCubit>().startMusic();
      unawaited(_scheduleNotifications());
    });
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondary) => const HomeShell(),
          transitionsBuilder: (context, anim, secondary, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 550),
        ),
      );
    });
  }

  Future<void> _scheduleNotifications() async {
    final notifications = context.read<LocalNotificationService>();
    final analytics = context.read<AnalyticsService>();
    final count = await notifications.scheduleNotifications();
    if (count > 0) {
      unawaited(
        analytics.logNotificationScheduled(count: count, source: 'launch'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MetaBackdrop(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 220)
                  .animate()
                  .slideY(begin: 0.18, duration: 650.ms, curve: Curves.easeOut)
                  .fadeIn()
                  .scale(begin: const Offset(0.92, 0.92)),
              SizedBox(height: 36.h),
              SizedBox(
                width: 30.w,
                height: 30.w,
                child: CircularProgressIndicator(
                  strokeWidth: 3.w,
                  color: MetaChrome.gold,
                ),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
