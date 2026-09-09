import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../meta/meta_chrome.dart';
import '../premium/premium_tokens.dart';
import 'goods_emoji.dart';

class CurrencyHud extends StatelessWidget {
  final int coins;
  final int gems;
  final bool compact;

  const CurrencyHud({
    super.key,
    required this.coins,
    required this.gems,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Chip(
          asset: '${PremiumTokens.uiRoot}/coin.png',
          fallbackIcon: Icons.monetization_on_rounded,
          color: MetaChrome.gold,
          value: coins,
          compact: compact,
        ),
        SizedBox(width: 8.w),
        _Chip(
          asset: '${PremiumTokens.uiRoot}/gem.png',
          fallbackIcon: Icons.diamond_rounded,
          color: const Color(0xFFCE93D8),
          value: gems,
          compact: compact,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String asset;
  final IconData fallbackIcon;
  final Color color;
  final int value;
  final bool compact;

  const _Chip({
    required this.asset,
    required this.fallbackIcon,
    required this.color,
    required this.value,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final h = compact ? 28.h : 34.h;
    return Container(
      height: h,
      padding: EdgeInsets.only(
        left: 4.w,
        right: compact ? 8.w : 10.w,
      ),
      decoration: BoxDecoration(
        color: const Color(0xEE2A1608),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: MetaChrome.brass, width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            asset,
            width: compact ? 18.w : 22.w,
            height: compact ? 18.w : 22.w,
            errorBuilder: (context, error, stack) =>
                Icon(fallbackIcon, color: color, size: compact ? 16.sp : 18.sp),
          ),
          SizedBox(width: 4.w),
          Text(
            _fmt(value),
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: compact ? 13.sp : 15.sp,
              color: MetaChrome.cream,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}K';
    if (n >= 1000) {
      return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return '$n';
  }
}

class GlowPlayButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const GlowPlayButton({
    super.key,
    required this.onPressed,
    this.label = 'PLAY',
  });

  @override
  Widget build(BuildContext context) {
    return MetaPlayButton(onPressed: onPressed, label: label);
  }
}

/// Official app logo asset used on splash, home, and brand surfaces.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 160});

  static const assetPath = 'assets/images/brand/app_logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size.w,
      height: size.w,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class MiaAvatar extends StatelessWidget {
  final double size;
  final String mood; // happy, excited, thinking, celebrating

  const MiaAvatar({
    super.key,
    this.size = 80,
    this.mood = 'happy',
  });

  @override
  Widget build(BuildContext context) {
    final face = switch (mood) {
      'excited' => 'starstruck',
      'thinking' => 'thinkingface',
      'celebrating' => 'partyingface',
      _ => 'grinningface',
    };
    final s = size.w;

    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8C45A), Color(0xFF8A5A10)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: MetaChrome.cream, width: 3.w),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmojiImage(type: 'grinningface', size: s * 0.45),
          EmojiImage(type: face, size: s * 0.18),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8));
  }
}
