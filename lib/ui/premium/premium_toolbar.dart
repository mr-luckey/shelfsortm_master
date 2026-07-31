import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_tokens.dart';

class PremiumActionToolbar extends StatelessWidget {
  final int undoCount;
  final int shuffleCount;
  final int freezeCount;
  final int extraCount;
  final int hintCount;
  final VoidCallback? onUndo;
  final VoidCallback? onShuffle;
  final VoidCallback? onFreeze;
  final VoidCallback? onExtraSlot;
  final VoidCallback? onHint;

  const PremiumActionToolbar({
    super.key,
    this.undoCount = 0,
    this.shuffleCount = 0,
    this.freezeCount = 0,
    this.extraCount = 0,
    this.hintCount = 0,
    this.onUndo,
    this.onShuffle,
    this.onFreeze,
    this.onExtraSlot,
    this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final tools = [
      (
        label: 'UNDO',
        icon: Icons.replay_rounded,
        color: PremiumTokens.undoBlue,
        count: undoCount,
        onTap: onUndo,
      ),
      (
        label: 'SHUFFLE',
        icon: Icons.auto_fix_high_rounded,
        color: PremiumTokens.shufflePurple,
        count: shuffleCount,
        onTap: onShuffle,
      ),
      (
        label: 'FREEZE',
        icon: Icons.ac_unit_rounded,
        color: PremiumTokens.freezeGreen,
        count: freezeCount,
        onTap: onFreeze,
      ),
      (
        label: 'EXTRA SLOT',
        icon: Icons.add_to_home_screen_rounded,
        color: PremiumTokens.slotPink,
        count: extraCount,
        onTap: onExtraSlot,
      ),
      (
        label: 'HINT',
        icon: Icons.lightbulb_rounded,
        color: PremiumTokens.hintOrange,
        count: hintCount,
        onTap: onHint,
      ),
    ];

    return Container(
      height: PremiumTokens.toolbarHeight,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final t in tools)
            _ToolButton(
              label: t.label,
              icon: t.icon,
              color: t.color,
              count: t.count,
              onTap: t.onTap ?? () {},
            ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _ToolButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1);
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
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
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 2,
                      ),
                      boxShadow: PremiumTokens.glossyShadow(y: 5, blur: 8),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 28),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: PremiumTokens.badgeRed,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '${widget.count}',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.15, 1.15),
                          duration: 900.ms,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
