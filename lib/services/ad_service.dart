import 'package:flutter/foundation.dart';

enum RewardType { hint, shuffle, autoSort, extraShelf, doubleCoins }

/// Production-shaped ad stub. Replace body with AdMob rewarded ads.
class AdService {
  Future<bool> showRewarded(RewardType type) async {
    // TODO: Integrate Google AdMob RewardedAd
    debugPrint('[AdService] Rewarded ad stub for $type — granting reward');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return true;
  }

  bool get bannerEnabled => true;
}
