import 'package:flutter/foundation.dart';

/// Official Google sample units. Use only when [AdsConfig.testMode] is true.
abstract final class GoogleTestAdUnits {
  static const androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const androidRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static const iosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const iosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  static String get banner => defaultTargetPlatform == TargetPlatform.iOS
      ? iosBanner
      : androidBanner;

  static String get interstitial =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? iosInterstitial
          : androidInterstitial;

  static String get rewarded => defaultTargetPlatform == TargetPlatform.iOS
      ? iosRewarded
      : androidRewarded;
}

/// Central AdMob configuration. Never invent production IDs.
///
/// Unit lists hold up to five IDs. Placements map a screen/feature name onto
/// one index. Empty strings disable that slot. No automatic fill waterfall.
class AdsConfig {
  const AdsConfig({
    this.isEnabled = true,
    // Force Google test units until production IDs are configured.
    this.testMode = true,
    this.bannerEnabled = true,
    this.interstitialEnabled = true,
    this.rewardedEnabled = true,
    // Production IDs: fill from AdMob console before release. Empty = disabled
    // outside testMode.
    this.bannerAdUnits = const ['', '', '', '', ''],
    this.interstitialAdUnits = const ['', '', '', '', ''],
    this.rewardedAdUnits = const ['', '', '', '', ''],
    this.bannerPlacements = const {
      'home': 0,
      'levels': 1,
      'game': 2,
      'result': 3,
      'profile': 4,
    },
    this.interstitialPlacements = const {
      'after_level': 0,
      'after_session': 1,
    },
    this.rewardedPlacements = const {
      'gift_box': 0,
      'hint': 0,
      'extra_shelf': 0,
      'double_coins': 0,
      'shuffle': 0,
      'auto_sort': 0,
    },
    this.minimumInterstitialInterval = const Duration(minutes: 2),
    this.maxRetries = 2,
    this.retryBackoff = const Duration(seconds: 30),
    this.requestTimeout = const Duration(seconds: 10),
  });

  final bool isEnabled;
  final bool testMode;
  final bool bannerEnabled;
  final bool interstitialEnabled;
  final bool rewardedEnabled;

  final List<String> bannerAdUnits;
  final List<String> interstitialAdUnits;
  final List<String> rewardedAdUnits;

  final Map<String, int> bannerPlacements;
  final Map<String, int> interstitialPlacements;
  final Map<String, int> rewardedPlacements;

  final Duration minimumInterstitialInterval;
  final int maxRetries;
  final Duration retryBackoff;
  final Duration requestTimeout;

  /// In testMode skip the production frequency gate so Google test ads show.
  Duration get effectiveInterstitialInterval =>
      testMode ? Duration.zero : minimumInterstitialInterval;

  String? bannerUnitId(String placement) {
    if (!_placementOk(bannerEnabled, bannerPlacements[placement])) return null;
    if (testMode) return GoogleTestAdUnits.banner;
    return _prodId(bannerAdUnits, bannerPlacements[placement]!);
  }

  String? interstitialUnitId(String placement) {
    if (!_placementOk(interstitialEnabled, interstitialPlacements[placement])) {
      return null;
    }
    if (testMode) return GoogleTestAdUnits.interstitial;
    return _prodId(interstitialAdUnits, interstitialPlacements[placement]!);
  }

  String? rewardedUnitId(String placement) {
    if (!_placementOk(rewardedEnabled, rewardedPlacements[placement])) {
      return null;
    }
    if (testMode) return GoogleTestAdUnits.rewarded;
    return _prodId(rewardedAdUnits, rewardedPlacements[placement]!);
  }

  bool _placementOk(bool enabled, int? index) =>
      isEnabled && enabled && index != null && index >= 0;

  String? _prodId(List<String> units, int index) {
    if (index >= units.length) return null;
    final id = units[index].trim();
    return id.isEmpty ? null : id;
  }
}
