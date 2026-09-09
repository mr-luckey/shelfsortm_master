import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';

class ToolBar extends StatelessWidget {
  final int freezes;
  final int shuffles;
  final int magnets;
  final int extras;
  final VoidCallback onUndo;
  final VoidCallback onFreeze;
  final VoidCallback onShuffle;
  final VoidCallback onMagnet;
  final VoidCallback onExtra;

  const ToolBar({
    super.key,
    required this.freezes,
    required this.shuffles,
    required this.magnets,
    required this.extras,
    required this.onUndo,
    required this.onFreeze,
    required this.onShuffle,
    required this.onMagnet,
    required this.onExtra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolBtn(icon: Icons.undo_rounded, label: 'Undo', onTap: onUndo),
            _ToolBtn(
              icon: Icons.ac_unit_rounded,
              label: 'Freeze',
              count: freezes,
              onTap: onFreeze,
              color: const Color(0xFF29B6F6),
            ),
            _ToolBtn(
              icon: Icons.shuffle_rounded,
              label: 'Shuffle',
              count: shuffles,
              onTap: onShuffle,
              color: AppColors.primary,
            ),
            _ToolBtn(
              icon: Icons.auto_awesome_rounded,
              label: 'Magnet',
              count: magnets,
              onTap: onMagnet,
              color: AppColors.accent,
            ),
            _ToolBtn(
              icon: Icons.add_box_rounded,
              label: 'Shelf',
              count: extras,
              onTap: onExtra,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback onTap;
  final Color color;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
    this.color = AppColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        width: 64.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.18),
                        color.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Icon(icon, color: color, size: 26.sp),
                ),
                if (count != null)
                  Positioned(
                    right: -4.w,
                    top: -4.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: count! > 0
                            ? AppColors.primary
                            : AppColors.textLight,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
