import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardType { hint, shuffle, autoSort, extraShelf, doubleCoins }

/// AdMob integration with Google test units in debug; replace for production.
class AdService {
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // Production: replace with your AdMob unit IDs from Play Console.
  static const _prodBanner = _testBanner;
  static const _prodRewarded = _testRewarded;

  bool _initialized = false;
  RewardedAd? _rewarded;
  bool _loadingRewarded = false;
  Completer<bool>? _rewardCompleter;

  String get _bannerUnit => kDebugMode ? _testBanner : _prodBanner;
  String get _rewardedUnit => kDebugMode ? _testRewarded : _prodRewarded;

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!isSupported) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _preloadRewarded();
    } catch (e) {
      debugPrint('[AdService] init failed: $e');
    }
  }

  bool get bannerEnabled => _initialized;

  Future<BannerAd?> createBanner() async {
    if (!_initialized) return null;
    final ad = BannerAd(
      adUnitId: _bannerUnit,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, err) {
          debugPrint('[AdService] banner failed: ${err.message}');
          ad.dispose();
        },
      ),
    );
    return ad;
  }

  void _preloadRewarded() {
    if (!_initialized || _loadingRewarded || _rewarded != null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: _rewardedUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewarded = null;
              _rewardCompleter?.complete(false);
              _rewardCompleter = null;
              _preloadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              debugPrint('[AdService] rewarded show failed: ${err.message}');
              ad.dispose();
              _rewarded = null;
              _rewardCompleter?.complete(false);
              _rewardCompleter = null;
              _preloadRewarded();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('[AdService] rewarded load failed: ${err.message}');
          _loadingRewarded = false;
        },
      ),
    );
  }

  Future<bool> showRewarded(RewardType type) async {
    if (!_initialized) {
      // Dev fallback when ads unavailable (desktop/web).
      debugPrint('[AdService] stub reward for $type');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return true;
    }

    if (_rewarded == null) {
      _preloadRewarded();
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
    final ad = _rewarded;
    if (ad == null) return false;

    _rewardCompleter = Completer<bool>();
    var earned = false;

    ad.show(
      onUserEarnedReward: (_, __) {
        earned = true;
        _rewardCompleter?.complete(true);
        _rewardCompleter = null;
      },
    );

    final result = await (_rewardCompleter?.future ??
        Future<bool>.delayed(const Duration(seconds: 2), () => earned));
    _rewarded = null;
    _preloadRewarded();
    return result;
  }

  void dispose() {
    _rewarded?.dispose();
    _rewarded = null;
  }
}
