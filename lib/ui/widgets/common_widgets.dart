import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_colors.dart';

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
          icon: Icons.monetization_on_rounded,
          color: AppColors.secondary,
          value: coins,
          compact: compact,
        ),
        const SizedBox(width: 8),
        _Chip(
          icon: Icons.diamond_rounded,
          color: AppColors.accent,
          value: gems,
          compact: compact,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final bool compact;

  const _Chip({
    required this.icon,
    required this.color,
    required this.value,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: compact ? 16 : 18),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 13 : 15,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 200,
        height: 64,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.04, 1.04),
            duration: 1200.ms,
            curve: Curves.easeInOut,
          ),
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
      'excited' => '🤩',
      'thinking' => '🤔',
      'celebrating' => '🥳',
      _ => '😊',
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('👧', style: TextStyle(fontSize: size * 0.45)),
          Text(face, style: TextStyle(fontSize: size * 0.18)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8));
  }
}
