import 'package:flutter/material.dart';

import '../premium/premium_gameplay_screen.dart';

/// Launch level with premium cupboard UI + real match engine.
void launchLevel(
  BuildContext context, {
  required int levelId,
  bool daily = false,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PremiumGameplayScreen(levelId: levelId, daily: daily),
    ),
  );
}

/// @deprecated Use [launchLevel]
Future<void> showLevelIntro(
  BuildContext context, {
  required int levelId,
  bool daily = false,
}) async {
  launchLevel(context, levelId: levelId, daily: daily);
}
