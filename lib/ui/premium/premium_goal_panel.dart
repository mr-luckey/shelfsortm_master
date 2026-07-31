import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'premium_tokens.dart';
import 'toy_item_type.dart';
import 'toy_item_widget.dart';

class PremiumGoalPanel extends StatelessWidget {
  final List<({ToyType type, int remaining})> goals;
  final String goalText;

  const PremiumGoalPanel({
    super.key,
    required this.goals,
    this.goalText = 'Sort all items by type',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: PremiumTokens.goalCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PremiumTokens.goalBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: 10,
            top: -1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: PremiumTokens.goalBlue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                'GOAL',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 6, 6),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    goalText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: PremiumTokens.goalText,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      height: 1.1,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final g in goals.take(4))
                        _GoalChip(type: g.type, remaining: g.remaining),
                    ],
                  ),
                ),
                const _RewardBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final ToyType type;
  final int remaining;

  const _GoalChip({required this.type, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ToyItemWidget.fromType(type: type, size: 28),
        const SizedBox(height: 1),
        Container(
          constraints: const BoxConstraints(minWidth: 18),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PremiumTokens.goalBorder),
          ),
          child: Text(
            '$remaining',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              color: PremiumTokens.goalText,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardBox extends StatelessWidget {
  const _RewardBox();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'REWARD',
            style: GoogleFonts.nunito(
              color: PremiumTokens.goalBlue,
              fontWeight: FontWeight.w900,
              fontSize: 8,
              letterSpacing: 0.3,
            ),
          ),
          Image.asset(
            '${PremiumTokens.uiRoot}/gift_box.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (_, error, stack) =>
                const Text('🎁', style: TextStyle(fontSize: 26)),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.06, 1.06),
                duration: 700.ms,
              )
              .then(delay: 4000.ms),
        ],
      ),
    );
  }
}
