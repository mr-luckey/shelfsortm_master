/// Central place for temporary / QA toggles.
/// Add new flags below — keep [unlockAllLevels] as the first flag.
abstract final class TestFlags {
  /// When `true`, every campaign level is playable.
  /// When `false`, normal lock progression applies (only unlocked levels).
  static const bool unlockAllLevels = false;
}
