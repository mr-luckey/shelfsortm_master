/// Central place for temporary / QA toggles.
/// Add new flags below — keep [unlockAllLevels] as the first flag.
abstract final class TestFlags {
  /// When `true`, every campaign level is playable.
  /// When `false`, normal lock progression applies (only unlocked levels).
  static const bool unlockAllLevels = false;

  /// When `true`, schedules 5 local notifications every 10 seconds (QA only).
  /// When `false`, normal 17:00 / 21:00 daily schedule applies.
  static const bool notificationTest = true;
}
