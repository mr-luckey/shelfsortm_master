import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/audio_service.dart';
import 'premium_tokens.dart';

/// Top HUD matching the wood-plank reference: pause · coins · timer · level.
class PremiumHudBar extends StatelessWidget {
  final int coins;
  final int level;
  final int timeLeft;
  final int timeLimit;
  final bool frozen;
  final VoidCallback? onPause;
  final VoidCallback? onAddCoins;

  const PremiumHudBar({
    super.key,
    this.coins = 0,
    this.level = 1,
    this.timeLeft = 0,
    this.timeLimit = 1,
    this.frozen = false,
    this.onPause,
    this.onAddCoins,
  });

  static const _ui = PremiumTokens.uiRoot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final scale = (w / 390).clamp(0.82, 1.08);
        final padH = 8.0 * scale;
        final plankH = 48.0 * scale;
        final timerSize = 78.0 * scale;
        final totalH = timerSize + 10 * scale;
        final sideW = (w - padH * 2 - timerSize) / 2;

        return SizedBox(
          height: totalH,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padH),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Wood plank with vines — vertical center of the timer.
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: plankH,
                    width: double.infinity,
                    child: Image.asset(
                      '$_ui/hud_plank.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A2A12),
                          borderRadius: BorderRadius.circular(plankH / 2),
                        ),
                      ),
                    ),
                  ),
                ),
                // Left / right content sit on the plank beside the timer.
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: plankH,
                    child: Row(
                      children: [
                        SizedBox(
                          width: sideW,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 6 * scale,
                              right: 4 * scale,
                            ),
                            child: Row(
                              children: [
                                _PauseBtn(
                                  size: 34 * scale,
                                  onTap: () {
                                    try {
                                      context.read<AudioService>().playButton();
                                    } catch (_) {
                                      HapticFeedback.selectionClick();
                                    }
                                    onPause?.call();
                                  },
                                ),
                                SizedBox(width: 5 * scale),
                                Expanded(
                                  child: _CoinsPill(
                                    value: _fmt(coins),
                                    scale: scale,
                                    onPlus: onAddCoins,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: timerSize),
                        // Spacer for level badge (drawn in Stack so it
                        // can be taller than the plank without overflow).
                        SizedBox(width: sideW),
                      ],
                    ),
                  ),
                ),
                // Level badge — full HUD height, right side.
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: padH + 4 * scale),
                    child: SizedBox(
                      width: sideW,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _LevelBadge(level: level, scale: scale),
                      ),
                    ),
                  ),
                ),
                // Center timer circle overlaps the plank.
                Align(
                  alignment: Alignment.center,
                  child: _TimerRing(
                    size: timerSize,
                    timeLeft: timeLeft,
                    timeLimit: timeLimit,
                    frozen: frozen,
                    scale: scale,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

class _PauseBtn extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _PauseBtn({required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: const _PauseBtnPainter(),
          child: Center(
            child: Icon(
              Icons.pause_rounded,
              color: const Color(0xFFFFE6A8),
              size: size * 0.48,
            ),
          ),
        ),
      ),
    );
  }
}

/// Wood disc + brass rim — matches settings/gear language on the plank.
class _PauseBtnPainter extends CustomPainter {
  const _PauseBtnPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Drop shadow
    canvas.drawCircle(
      c.translate(0, 1.5),
      r,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Outer brass rim
    final rim = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF0D78A), Color(0xFFB8860B), Color(0xFF8A5A10)],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, rim);

    // Inner dark wood face
    final face = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5A3418), Color(0xFF2E1608)],
      ).createShader(Rect.fromCircle(center: c, radius: r * 0.78));
    canvas.drawCircle(c, r * 0.78, face);

    // Soft highlight
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.72),
      -2.4,
      1.4,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08
        ..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CoinsPill extends StatelessWidget {
  final String value;
  final double scale;
  final VoidCallback? onPlus;

  const _CoinsPill({
    required this.value,
    required this.scale,
    this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final h = 30.0 * scale;
    return Container(
      height: h,
      padding: EdgeInsets.only(left: 3 * scale, right: 3 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1608).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(h / 2),
        border: Border.all(color: const Color(0xFFE0B84A), width: 1.6 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            '${PremiumTokens.uiRoot}/coin.png',
            width: 22 * scale,
            height: 22 * scale,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.monetization_on,
              color: PremiumTokens.coinGold,
              size: 20 * scale,
            ),
          ),
          SizedBox(width: 3 * scale),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12 * scale,
                height: 1.1,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 2),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onPlus?.call();
            },
            child: Container(
              width: 20 * scale,
              height: 20 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF7CDB5A), Color(0xFF2E9B2A)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(Icons.add, color: Colors.white, size: 14 * scale),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final double scale;

  const _LevelBadge({required this.level, required this.scale});

  @override
  Widget build(BuildContext context) {
    final w = 56.0 * scale;
    final h = 64.0 * scale;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            '${PremiumTokens.uiRoot}/level_shield.png',
            width: w,
            height: h,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => Container(
              width: w * 0.85,
              height: h * 0.85,
              decoration: BoxDecoration(
                color: const Color(0xFF3A2410),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0B84A), width: 2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 6 * scale, bottom: 10 * scale),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'LEVEL',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 8 * scale,
                    letterSpacing: 0.6,
                    height: 1,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 2),
                    ],
                  ),
                ),
                SizedBox(height: 1 * scale),
                Text(
                  '$level',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20 * scale,
                    height: 1,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final double size;
  final int timeLeft;
  final int timeLimit;
  final bool frozen;
  final double scale;

  const _TimerRing({
    required this.size,
    required this.timeLeft,
    required this.timeLimit,
    required this.frozen,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = timeLimit <= 0 ? 1.0 : (timeLeft / timeLimit).clamp(0.0, 1.0);
    final mins = timeLeft ~/ 60;
    final secs = timeLeft % 60;
    final text =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    Color ring;
    if (frozen) {
      ring = const Color(0xFF4FC3F7);
    } else if (ratio <= 0.1) {
      ring = const Color(0xFFE53935);
    } else if (ratio <= 0.25) {
      ring = const Color(0xFFFF9800);
    } else {
      ring = const Color(0xFF8BC34A);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _TimerRingPainter(progress: ratio, color: ring),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                '${PremiumTokens.uiRoot}/hourglass.png',
                width: 16 * scale,
                height: 22 * scale,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.hourglass_bottom,
                  color: const Color(0xFFE0B84A),
                  size: 16 * scale,
                ),
              ),
              SizedBox(height: 1 * scale),
              Text(
                text,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13 * scale,
                  height: 1,
                  shadows: const [
                    Shadow(color: Colors.black87, blurRadius: 3),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _TimerRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Outer gold rim
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5D76E), Color(0xFFB8860B), Color(0xFFF0C14B)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Inner dark wood face
    canvas.drawCircle(c, r * 0.82, Paint()..color = const Color(0xFF3A2410));
    canvas.drawCircle(
      c,
      r * 0.82,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF5A3820).withValues(alpha: 0.55),
            const Color(0xFF2A1608),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.82)),
    );

    // Track
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1A1008).withValues(alpha: 0.55);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.88),
      -math.pi / 2,
      math.pi * 2,
      false,
      track,
    );

    // Progress
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14
      ..strokeCap = StrokeCap.round
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 0.4);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.88),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress || old.color != color;
}
