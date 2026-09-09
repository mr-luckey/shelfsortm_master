import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        final h = 70.h;

        return SizedBox(
          height: h,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Crop out baked REWARD / gift on the right of the art.
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
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
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: PremiumTokens.goalBorder,
                            width: 2.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10.w,
                top: -2.h,
                child: Image.asset(
                  '$_ui/ribbon_goal.png',
                  height: 22.h,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stack) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'GOAL',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 4.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48.w,
                      child: Text(
                        goalText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF4A2E14),
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5.sp,
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

  const _GoalChip({
    required this.type,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final icon = 34.w;
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
              fontSize: 18.sp,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          constraints: BoxConstraints(minWidth: 15.w),
          padding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: 0.5.h,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3C4),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD4B56A), width: 1.w),
          ),
          child: Text(
            '$remaining',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w900,
              fontSize: 9.sp,
              color: const Color(0xFF4A2E14),
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}
