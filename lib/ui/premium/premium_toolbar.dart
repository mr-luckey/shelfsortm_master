import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/audio_service.dart';
import 'premium_tokens.dart';

/// Freeze + Hint — compact pair beside the goal panel (bottom stays free for ads).
class PremiumBoosterRail extends StatelessWidget {
  final int freezeCount;
  final int hintCount;
  final VoidCallback? onFreeze;
  final VoidCallback? onHint;

  const PremiumBoosterRail({
    super.key,
    this.freezeCount = 0,
    this.hintCount = 0,
    this.onFreeze,
    this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _BoosterBtn(
          icon: Icons.ac_unit_rounded,
          color: PremiumTokens.freezeGreen,
          count: freezeCount,
          label: 'FREEZE',
          onTap: onFreeze ?? () {},
        ),
        const SizedBox(width: 6),
        _BoosterBtn(
          icon: Icons.lightbulb_rounded,
          color: PremiumTokens.hintOrange,
          count: hintCount,
          label: 'HINT',
          onTap: onHint ?? () {},
        ),
      ],
    );
  }
}

class _BoosterBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;
  final VoidCallback onTap;

  const _BoosterBtn({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
    required this.onTap,
  });

  @override
  State<_BoosterBtn> createState() => _BoosterBtnState();
}

class _BoosterBtnState extends State<_BoosterBtn> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.94),
      onTapUp: (_) {
        setState(() => _scale = 1);
        try {
          context.read<AudioService>().playButton();
        } catch (_) {
          HapticFeedback.mediumImpact();
        }
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(widget.color, Colors.white, 0.25)!,
                        widget.color,
                        Color.lerp(widget.color, Colors.black, 0.15)!,
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFE8C9A0),
                      width: 1.5,
                    ),
                    boxShadow: PremiumTokens.glossyShadow(y: 3, blur: 6),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 22),
                ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: PremiumTokens.badgeRed,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1.4),
                    ),
                    child: Text(
                      '${widget.count}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 900.ms,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                fontSize: 8,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
