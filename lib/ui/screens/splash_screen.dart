import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/audio_service.dart';
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
      if (mounted) context.read<AudioService>().startMusic();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MetaBackdrop(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MiaAvatar(size: 120, mood: 'happy')
                  .animate()
                  .slideY(begin: 0.25, duration: 650.ms, curve: Curves.easeOut)
                  .fadeIn(),
              const SizedBox(height: 20),
              const MetaTitle('ShelfSort Master', size: 34)
                  .animate()
                  .fadeIn(delay: 280.ms)
                  .scale(begin: const Offset(0.92, 0.92)),
              const SizedBox(height: 8),
              Text(
                'Sort · Match · Master the shelves',
                style: GoogleFonts.nunito(
                  color: MetaChrome.cream.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ).animate().fadeIn(delay: 480.ms),
              const SizedBox(height: 36),
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
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
