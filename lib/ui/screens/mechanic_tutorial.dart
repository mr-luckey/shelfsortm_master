import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../engine/mechanics/mechanic_ids.dart';

/// Micro-tutorials for each dynamic mechanic (PRD §6A.16).
abstract final class MechanicTutorials {
  static const Map<String, (String title, String body)> copy = {
    MechanicIds.hiddenBackRow: (
      'Hidden Back Row',
      'Clear the front items to reveal what\'s behind.',
    ),
    MechanicIds.movingBottomTray: (
      'Moving Tray',
      'The tray is moving! Tap a slot when it\'s ready.',
    ),
    MechanicIds.slidingShelves: (
      'Sliding Shelf',
      'Some slots hide when the shelf slides. Watch carefully!',
    ),
    MechanicIds.rotatingTray: (
      'Rotating Tray',
      'The tray rotates after moves — plan ahead.',
    ),
    MechanicIds.conveyorShelf: (
      'Conveyor',
      'Pick items from the conveyor before they cycle away.',
    ),
    MechanicIds.lockedItems: (
      'Locked Items',
      'Locked goods unlock when you meet their condition.',
    ),
    MechanicIds.mysteryBoxes: (
      'Mystery Boxes',
      'Open mystery boxes to reveal hidden goods.',
    ),
    MechanicIds.stackedItems: (
      'Stacked Items',
      'Clear the top of each stack to reach items below.',
    ),
    MechanicIds.frozenItems: (
      'Frozen Items',
      'Crack the ice to free frozen items.',
    ),
    MechanicIds.movingDivider: (
      'Moving Divider',
      'The divider moves — plan your groups carefully.',
    ),
    MechanicIds.chainRelease: (
      'Chain Release',
      'Complete groups to trigger a chain of reveals!',
    ),
  };

  static String prefsKey(String mechanicId) => 'mech_tut_$mechanicId';

  static Future<bool> wasSeen(String mechanicId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey(mechanicId)) ?? false;
  }

  static Future<void> markSeen(String mechanicId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey(mechanicId), true);
  }

  /// Returns the first unseen mechanic among [active], or null.
  static Future<String?> firstUnseen(List<String> active) async {
    for (final id in active) {
      if (copy.containsKey(id) && !(await wasSeen(id))) return id;
    }
    return null;
  }
}

/// Compact one-shot overlay for a new mechanic.
class MechanicTutorialSheet extends StatelessWidget {
  final String mechanicId;
  final VoidCallback onDismiss;

  const MechanicTutorialSheet({
    super.key,
    required this.mechanicId,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final pair = MechanicTutorials.copy[mechanicId];
    final title = pair?.$1 ?? 'New Mechanic';
    final body = pair?.$2 ?? 'Something new appeared on this level!';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(22.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, color: const Color(0xFFFF6B35), size: 32.sp),
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8.h),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
            ),
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await MechanicTutorials.markSeen(mechanicId);
                  onDismiss();
                },
                child: const Text('Got it!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
