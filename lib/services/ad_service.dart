import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ads_config.dart';
import 'network_guard.dart';

enum RewardType { hint, shuffle, autoSort, extraShelf, doubleCoins }

enum RewardedAdOutcome { earned, skipped, unavailable }

/// Network-aware AdMob manager. Placement-based IDs. No waterfall.
/// At most one full-screen ad (interstitial or rewarded) at a time.
class AdService extends ChangeNotifier {
  AdService({
    AdsConfig config = const AdsConfig(),
    NetworkGuard? network,
  })  : _config = config,
        _network = network ?? NetworkGuard();

  final AdsConfig _config;
  final NetworkGuard _network;

  bool _sdkInitialized = false;
  bool _initializing = false;
  bool _fullScreenShowing = false;
  DateTime? _lastFullScreenAt;

  InterstitialAd? _interstitial;
  String? _interstitialPlacement;
  RewardedAd? _rewarded;
  String? _rewardedPlacement;

  int _interstitialAttempts = 0;
  int _rewardedAttempts = 0;
  Timer? _interstitialRetry;
  Timer? _rewardedRetry;

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  bool get isReady => _sdkInitialized;
  bool get isOnline => _network.isOnline;
  bool get isFullScreenShowing => _fullScreenShowing;
  bool get hasRewardedAd => _rewarded != null;
  bool get bannerEnabled =>
      _sdkInitialized && _config.bannerEnabled && isOnline;
  bool get adsUiEnabled => isSupported && isOnline && _config.isEnabled;

  String placementForReward(RewardType type) {
    switch (type) {
      case RewardType.hint:
        return 'hint';
      case RewardType.shuffle:
        return 'shuffle';
      case RewardType.autoSort:
        return 'auto_sort';
      case RewardType.extraShelf:
        return 'extra_shelf';
      case RewardType.doubleCoins:
        return 'double_coins';
    }
  }

  Future<void> init() async {
    if (!isSupported) return;
    await _network.start(
      onOnline: _onNetworkRestored,
      onOffline: _onNetworkLost,
    );
    notifyListeners();
    if (_network.isOnline) {
      await _ensureSdk();
    }
  }

  @override
  void dispose() {
    _interstitialRetry?.cancel();
    _rewardedRetry?.cancel();
    _interstitial?.dispose();
    _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
    unawaited(_network.dispose());
    super.dispose();
  }

  /// Load a banner for one visible placement. Caller owns dispose.
  Future<BannerAd?> loadBanner({
    required String placement,
    AdSize size = AdSize.banner,
  }) async {
    final unitId = _config.bannerUnitId(placement);
    if (unitId == null) return null;
    if (!await _canUseAds()) return null;
    try {
      final completer = Completer<BannerAd?>();
      final ad = BannerAd(
        adUnitId: unitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (loaded) {
            if (!completer.isCompleted) completer.complete(loaded as BannerAd);
          },
          onAdFailedToLoad: (failed, error) {
            debugPrint('[AdService] banner no-fill [$placement]: $error');
            failed.dispose();
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );
      await ad.load();
      return completer.future.timeout(
        _config.requestTimeout,
        onTimeout: () {
          ad.dispose();
          return null;
        },
      );
    } catch (error, stack) {
      debugPrint('[AdService] loadBanner failed: $error\n$stack');
      return null;
    }
  }

  /// Legacy helper used by [AdBannerWidget] callers that still expect create+load.
  Future<BannerAd?> createBanner({String placement = 'home'}) =>
      loadBanner(placement: placement);

  Future<void> preloadInterstitial({String placement = 'after_level'}) async {
    if (_interstitial != null && _interstitialPlacement == placement) return;
    final unitId = _config.interstitialUnitId(placement);
    if (unitId == null) return;
    if (!await _canUseAds()) return;
    if (_interstitialAttempts > _config.maxRetries) return;

    try {
      _interstitialRetry?.cancel();
      _interstitial?.dispose();
      _interstitial = null;
      debugPrint('[AdService] load interstitial [$placement] → $unitId');
      final completer = Completer<InterstitialAd?>();
      await InterstitialAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: completer.complete,
          onAdFailedToLoad: (error) {
            debugPrint(
              '[AdService] interstitial no-fill [$placement]: $error',
            );
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );
      final ad = await completer.future.timeout(
        _config.requestTimeout,
        onTimeout: () => null,
      );
      if (ad == null) {
        _interstitialAttempts++;
        _scheduleInterstitialRetry(placement);
        return;
      }
      _interstitialAttempts = 0;
      _interstitialPlacement = placement;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (_) {
          _fullScreenShowing = true;
          notifyListeners();
        },
        onAdDismissedFullScreenContent: (dismissed) {
          _fullScreenShowing = false;
          _lastFullScreenAt = DateTime.now();
          dismissed.dispose();
          _interstitial = null;
          notifyListeners();
        },
        onAdFailedToShowFullScreenContent: (failed, error) {
          debugPrint('[AdService] interstitial show failed: $error');
          _fullScreenShowing = false;
          failed.dispose();
          _interstitial = null;
          notifyListeners();
        },
      );
      _interstitial = ad;
    } catch (error, stack) {
      debugPrint('[AdService] preloadInterstitial failed: $error\n$stack');
    }
  }

  /// Natural-break interstitial. Skips if another full-screen is up or interval.
  Future<bool> showInterstitial({String placement = 'after_level'}) async {
    if (_fullScreenShowing) return false;
    if (!_frequencyAllowsInterstitial()) return false;
    if (_interstitial == null || _interstitialPlacement != placement) {
      await preloadInterstitial(placement: placement);
    }
    final ad = _interstitial;
    if (ad == null) return false;
    try {
      await ad.show();
      return true;
    } catch (error, stack) {
      debugPrint('[AdService] showInterstitial failed: $error\n$stack');
      ad.dispose();
      _interstitial = null;
      return false;
    }
  }

  Future<void> preloadRewarded({String placement = 'gift_box'}) async {
    if (_rewarded != null && _rewardedPlacement == placement) return;
    final unitId = _config.rewardedUnitId(placement);
    if (unitId == null) return;
    if (!await _canUseAds()) return;
    if (_rewardedAttempts > _config.maxRetries) return;

    try {
      _rewardedRetry?.cancel();
      _rewarded?.dispose();
      _rewarded = null;
      debugPrint('[AdService] load rewarded [$placement] → $unitId');
      final completer = Completer<RewardedAd?>();
      await RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: completer.complete,
          onAdFailedToLoad: (error) {
            debugPrint('[AdService] rewarded no-fill [$placement]: $error');
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );
      final ad = await completer.future.timeout(
        _config.requestTimeout,
        onTimeout: () => null,
      );
      if (ad == null) {
        _rewardedAttempts++;
        _scheduleRewardedRetry(placement);
        notifyListeners();
        return;
      }
      _rewardedAttempts = 0;
      _rewardedPlacement = placement;
      _rewarded = ad;
      notifyListeners();
    } catch (error, stack) {
      debugPrint('[AdService] preloadRewarded failed: $error\n$stack');
    }
  }

  /// User-initiated only. Grant only when [RewardedAdOutcome.earned].
  Future<RewardedAdOutcome> showRewardedAd({
    String placement = 'gift_box',
  }) async {
    if (_fullScreenShowing) return RewardedAdOutcome.unavailable;
    if (!isOnline) return RewardedAdOutcome.unavailable;

    if (_rewarded == null || _rewardedPlacement != placement) {
      await preloadRewarded(placement: placement);
    }
    final ad = _rewarded;
    if (ad == null) return RewardedAdOutcome.unavailable;

    final completer = Completer<RewardedAdOutcome>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _fullScreenShowing = true;
        notifyListeners();
      },
      onAdDismissedFullScreenContent: (dismissed) {
        _fullScreenShowing = false;
        _lastFullScreenAt = DateTime.now();
        dismissed.dispose();
        _rewarded = null;
        notifyListeners();
        if (!completer.isCompleted) {
          completer.complete(
            earned ? RewardedAdOutcome.earned : RewardedAdOutcome.skipped,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (failed, error) {
        debugPrint('[AdService] rewarded show failed: $error');
        _fullScreenShowing = false;
        failed.dispose();
        _rewarded = null;
        notifyListeners();
        if (!completer.isCompleted) {
          completer.complete(RewardedAdOutcome.unavailable);
        }
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          earned = true;
        },
      );
      return completer.future;
    } catch (error, stack) {
      debugPrint('[AdService] showRewardedAd failed: $error\n$stack');
      ad.dispose();
      _rewarded = null;
      return RewardedAdOutcome.unavailable;
    }
  }

  /// Compatibility API used by progress / continue flows.
  Future<bool> showRewarded(RewardType type) async {
    if (!isSupported || !_config.isEnabled) {
      // Desktop/web / ads-off: allow local tooling without AdMob.
      debugPrint('[AdService] stub reward for $type');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return true;
    }
    final outcome = await showRewardedAd(
      placement: placementForReward(type),
    );
    return outcome == RewardedAdOutcome.earned;
  }

  void _onNetworkRestored() {
    _interstitialAttempts = 0;
    _rewardedAttempts = 0;
    unawaited(_ensureSdk());
    notifyListeners();
  }

  void _onNetworkLost() {
    _interstitialRetry?.cancel();
    _rewardedRetry?.cancel();
    _interstitial?.dispose();
    _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
    notifyListeners();
  }

  Future<bool> _canUseAds() async {
    if (!_config.isEnabled) return false;
    if (!_network.isOnline) return false;
    return _ensureSdk();
  }

  Future<bool> _ensureSdk() async {
    if (_sdkInitialized) return true;
    if (!_network.isOnline || !_config.isEnabled) return false;
    if (_initializing) return _sdkInitialized;
    _initializing = true;
    try {
      await MobileAds.instance.initialize();
      _sdkInitialized = true;
      notifyListeners();
    } catch (error, stack) {
      debugPrint('[AdService] MobileAds.initialize failed: $error\n$stack');
      _sdkInitialized = false;
    } finally {
      _initializing = false;
    }
    return _sdkInitialized;
  }

  bool _frequencyAllowsInterstitial() {
    final last = _lastFullScreenAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >=
        _config.effectiveInterstitialInterval;
  }

  void _scheduleInterstitialRetry(String placement) {
    if (!_network.isOnline) return;
    if (_interstitialAttempts > _config.maxRetries) return;
    _interstitialRetry?.cancel();
    final delay = _config.retryBackoff * _interstitialAttempts;
    _interstitialRetry = Timer(delay, () {
      unawaited(preloadInterstitial(placement: placement));
    });
  }

  void _scheduleRewardedRetry(String placement) {
    if (!_network.isOnline) return;
    if (_rewardedAttempts > _config.maxRetries) return;
    _rewardedRetry?.cancel();
    final delay = _config.retryBackoff * _rewardedAttempts;
    _rewardedRetry = Timer(delay, () {
      unawaited(preloadRewarded(placement: placement));
    });
  }
}
