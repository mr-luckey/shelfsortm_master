import 'package:flutter_test/flutter_test.dart';

import 'package:shelfsortm_master/config/ads_config.dart';
import 'package:shelfsortm_master/config/notification_config.dart';

void main() {
  group('AdsConfig placements', () {
    test('maps named placements without waterfall', () {
      const config = AdsConfig(
        testMode: false,
        bannerAdUnits: ['b0', 'b1', 'b2', 'b3', 'b4'],
        interstitialAdUnits: ['i0', 'i1', '', '', ''],
        rewardedAdUnits: ['r0', '', '', '', ''],
      );

      expect(config.bannerUnitId('home'), 'b0');
      expect(config.bannerUnitId('game'), 'b2');
      expect(config.interstitialUnitId('after_level'), 'i0');
      expect(config.interstitialUnitId('after_session'), 'i1');
      expect(config.rewardedUnitId('gift_box'), 'r0');
      expect(config.rewardedUnitId('missing'), isNull);
    });

    test('empty production slot disables that placement', () {
      const config = AdsConfig(
        testMode: false,
        interstitialAdUnits: ['', '', '', '', ''],
      );
      expect(config.interstitialUnitId('after_level'), isNull);
    });

    test('testMode uses Google sample units', () {
      const config = AdsConfig(testMode: true);
      expect(config.bannerUnitId('home'), GoogleTestAdUnits.banner);
      expect(config.interstitialUnitId('after_level'), GoogleTestAdUnits.interstitial);
      expect(config.rewardedUnitId('gift_box'), GoogleTestAdUnits.rewarded);
    });
  });

  group('NotificationConfig', () {
    test('defaults alternate 17:00 / 21:00 for 14 days', () {
      const config = NotificationConfig();
      expect(config.scheduleTimes, ['17:00', '21:00']);
      expect(config.rotationMode, NotificationRotationMode.alternate);
      expect(config.daysToSchedule, 14);
      expect(config.assetPath, 'assets/notifications/notifications.json');
    });
  });
}
