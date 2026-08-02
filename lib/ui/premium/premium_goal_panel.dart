import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/emoji_assets.dart';
import 'premium_tokens.dart';

/// Goal board — products only (no reward).
class PremiumGoalPanel extends StatelessWidget {
  final List<({String type, int remaining})> goals;
  final String goalText;

  const PremiumGoalPanel({
    super.key,
    required this.goals,
    this.goalText = 'Clear all sets',
  });

  static const _ui = PremiumTokens.uiRoot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 280).clamp(0.85, 1.1);
        final h = 70.0 * scale;

        return SizedBox(
          height: h,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Crop out baked REWARD / gift on the right of the art.
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12 * scale),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.78,
                    child: Image.asset(
                      '$_ui/goal_board.png',
                      fit: BoxFit.cover,
                      height: h,
                      width: constraints.maxWidth / 0.78,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stack) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: PremiumTokens.goalCream,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: PremiumTokens.goalBorder,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10 * scale,
                top: -2 * scale,
                child: Image.asset(
                  '$_ui/ribbon_goal.png',
                  height: 22 * scale,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stack) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 * scale,
                      vertical: 2 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'GOAL',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10 * scale,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  8 * scale,
                  16 * scale,
                  8 * scale,
                  4 * scale,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48 * scale,
                      child: Text(
                        goalText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF4A2E14),
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5 * scale,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, chipBox) {
                          return SizedBox(
                            height: chipBox.maxHeight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (final g in goals.take(4))
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: _GoalChip(
                                        type: g.type,
                                        remaining: g.remaining,
                                        scale: scale,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GoalChip extends StatelessWidget {
  final String type;
  final int remaining;
  final double scale;

  const _GoalChip({
    required this.type,
    required this.remaining,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final icon = 34.0 * scale;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          EmojiAssets.pathFor(type),
          width: icon,
          height: icon,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => Text(
            '?',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 18 * scale,
            ),
          ),
        ),
        SizedBox(height: 1 * scale),
        Container(
          constraints: BoxConstraints(minWidth: 15 * scale),
          padding: EdgeInsets.symmetric(
            horizontal: 4 * scale,
            vertical: 0.5 * scale,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3C4),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD4B56A), width: 1),
          ),
          child: Text(
            '$remaining',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 9 * scale,
              color: const Color(0xFF4A2E14),
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}
