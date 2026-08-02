import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_tokens.dart';

class PremiumHudBar extends StatelessWidget {
  final int coins;
  final int gems;
  final int level;
  final int stars;
  final int timeLeft;
  final int timeLimit;
  final bool frozen;
  final VoidCallback? onSettings;
  final VoidCallback? onShop;
  final VoidCallback? onAddCoins;
  final VoidCallback? onAddGems;

  const PremiumHudBar({
    super.key,
    this.coins = 0,
    this.gems = 0,
    this.level = 1,
    this.stars = 0,
    this.timeLeft = 0,
    this.timeLimit = 1,
    this.frozen = false,
    this.onSettings,
    this.onShop,
    this.onAddCoins,
    this.onAddGems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: PremiumTokens.hudHeight,
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PremiumTokens.hudNavy, PremiumTokens.hudNavyDark],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: PremiumTokens.hudBlueLight.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: PremiumTokens.glossyShadow(y: 6, blur: 14),
      ),
      child: Row(
        children: [
          _HudCircleBtn(
            icon: Icons.settings_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              onSettings?.call();
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _CurrencyPill(
              asset: '${PremiumTokens.uiRoot}/coin.png',
              fallbackIcon: Icons.monetization_on_rounded,
              iconColor: PremiumTokens.coinGold,
              value: _fmt(coins),
              onPlus: onAddCoins,
            ),
          ),
          const SizedBox(width: 4),
          _TimerPill(
            timeLeft: timeLeft,
            timeLimit: timeLimit,
            frozen: frozen,
          ),
          const SizedBox(width: 4),
          _LevelPanel(level: level, stars: stars),
          const SizedBox(width: 4),
          Expanded(
            child: _CurrencyPill(
              asset: '${PremiumTokens.uiRoot}/gem.png',
              fallbackIcon: Icons.diamond_rounded,
              iconColor: PremiumTokens.gemMagenta,
              value: '$gems',
              onPlus: onAddGems,
            ),
          ),
          const SizedBox(width: 4),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _HudCircleBtn(
                icon: Icons.shopping_cart_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onShop?.call();
                },
              ),
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: PremiumTokens.badgeRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.25, 1.25),
                      duration: 800.ms,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return '$n';
  }
}

class _TimerPill extends StatelessWidget {
  final int timeLeft;
  final int timeLimit;
  final bool frozen;

  const _TimerPill({
    required this.timeLeft,
    required this.timeLimit,
    required this.frozen,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = timeLimit <= 0 ? 1.0 : timeLeft / timeLimit;
    final Color bg;
    final Color border;
    if (frozen) {
      bg = const Color(0xFFB3E5FC);
      border = const Color(0xFF0288D1);
    } else if (ratio <= 0.10) {
      bg = const Color(0xFFFFCDD2);
      border = const Color(0xFFC62828);
    } else if (ratio <= 0.25) {
      bg = const Color(0xFFFFE0B2);
      border = const Color(0xFFEF6C00);
    } else if (ratio <= 0.50) {
      bg = const Color(0xFFFFF9C4);
      border = const Color(0xFFF9A825);
    } else {
      bg = const Color(0xFFC8E6C9);
      border = const Color(0xFF43A047);
    }

    final mins = timeLeft ~/ 60;
    final secs = timeLeft % 60;
    final text =
        '${mins.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';

    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            frozen ? Icons.ac_unit : Icons.timer_outlined,
            size: 16,
            color: border,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.nunito(
              color: const Color(0xFF1A237E),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );

    if (!frozen && timeLeft > 0 && timeLeft <= 5) {
      pill = pill
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.06, 1.06),
            duration: 350.ms,
          );
    }
    return pill;
  }
}

class _HudCircleBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HudCircleBtn({required this.icon, required this.onTap});

  @override
  State<_HudCircleBtn> createState() => _HudCircleBtnState();
}

class _HudCircleBtnState extends State<_HudCircleBtn> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: PremiumTokens.glossyBlue,
            border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 2),
            boxShadow: PremiumTokens.glossyShadow(blur: 6),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final String asset;
  final IconData fallbackIcon;
  final Color iconColor;
  final String value;
  final VoidCallback? onPlus;

  const _CurrencyPill({
    required this.asset,
    required this.fallbackIcon,
    required this.iconColor,
    required this.value,
    this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 4, right: 4),
      decoration: BoxDecoration(
        color: PremiumTokens.hudBlue.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Image.asset(
            asset,
            width: 22,
            height: 22,
            errorBuilder: (_, error, stack) =>
                Icon(fallbackIcon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          _PlusBtn(onTap: onPlus),
        ],
      ),
    );
  }
}

class _PlusBtn extends StatefulWidget {
  final VoidCallback? onTap;

  const _PlusBtn({this.onTap});

  @override
  State<_PlusBtn> createState() => _PlusBtnState();
}

class _PlusBtnState extends State<_PlusBtn> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1);
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: PremiumTokens.plusGreen,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            boxShadow: PremiumTokens.glossyShadow(y: 2, blur: 4),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 15),
        ),
      ),
    );
  }
}

class _LevelPanel extends StatelessWidget {
  final int level;
  final int stars;

  const _LevelPanel({required this.level, required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [PremiumTokens.hudBlue, PremiumTokens.hudNavy],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: PremiumTokens.glossyShadow(y: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LEVEL $level',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Icon(
                i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                color: PremiumTokens.starGold,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
