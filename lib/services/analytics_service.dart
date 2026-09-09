import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/analytics_config.dart';

/// Central analytics facade. Never throw to callers. Never send PII.
///
/// Logs only after [Firebase.initializeApp] has succeeded. Without Firebase
/// platform config (`google-services.json` / `GoogleService-Info.plist`), this
/// service stays idle and gameplay continues.
class AnalyticsService {
  AnalyticsService({
    AnalyticsConfig config = const AnalyticsConfig(),
    FirebaseAnalytics? analytics,
  })  : _config = config,
        _analytics = analytics;

  final AnalyticsConfig _config;
  FirebaseAnalytics? _analytics;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    if (!_config.enabled) return;
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint(
          '[Analytics] Firebase not initialized — logging disabled until '
          'platform config is added',
        );
        return;
      }
      _analytics ??= FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      _ready = true;
    } catch (error, stack) {
      debugPrint('[Analytics] init failed: $error\n$stack');
      _ready = false;
    }
  }

  Future<void> logLevelStarted({
    int? levelNumber,
    String? difficulty,
    int? attemptNumber,
    String? source,
  }) {
    return logEvent(AnalyticsConfig.eventLevelStarted, {
      'level_number': ?levelNumber,
      'difficulty': ?difficulty,
      'attempt_number': ?attemptNumber,
      'source': ?source,
    });
  }

  Future<void> logLevelCompleted({
    int? levelNumber,
    String? difficulty,
    int? moves,
    int? timeSeconds,
    int? attemptNumber,
    String? source,
  }) {
    return logEvent(AnalyticsConfig.eventLevelCompleted, {
      'level_number': ?levelNumber,
      'difficulty': ?difficulty,
      'moves': ?moves,
      'time_seconds': ?timeSeconds,
      'attempt_number': ?attemptNumber,
      'source': ?source,
    });
  }

  Future<void> logLevelFailed({
    int? levelNumber,
    String? difficulty,
    int? moves,
    int? timeSeconds,
    int? attemptNumber,
    String? source,
  }) {
    return logEvent(AnalyticsConfig.eventLevelFailed, {
      'level_number': ?levelNumber,
      'difficulty': ?difficulty,
      'moves': ?moves,
      'time_seconds': ?timeSeconds,
      'attempt_number': ?attemptNumber,
      'source': ?source,
    });
  }

  Future<void> logLevelAbandoned({
    int? levelNumber,
    String? difficulty,
    String? source,
  }) {
    return logEvent(AnalyticsConfig.eventLevelAbandoned, {
      'level_number': ?levelNumber,
      'difficulty': ?difficulty,
      'source': ?source,
    });
  }

  Future<void> logHintUsed({int? levelNumber, String? source}) {
    return logEvent(AnalyticsConfig.eventHintUsed, {
      'level_number': ?levelNumber,
      'source': ?source,
    });
  }

  Future<void> logRewardClaimed({String? rewardType, String? source}) {
    return logEvent(AnalyticsConfig.eventRewardClaimed, {
      'reward_type': ?rewardType,
      'source': ?source,
    });
  }

  Future<void> logDailyRewardClaimed({int? day, String? source}) {
    return logEvent(AnalyticsConfig.eventDailyRewardClaimed, {
      'day': ?day,
      'source': ?source,
    });
  }

  Future<void> logNotificationOpened({
    String? notificationId,
    String? source,
  }) {
    return logEvent(AnalyticsConfig.eventNotificationOpened, {
      'notification_id': ?notificationId,
      'source': ?source,
    });
  }

  Future<void> logNotificationScheduled({int? count, String? source}) {
    return logEvent(AnalyticsConfig.eventNotificationScheduled, {
      'count': ?count,
      'source': ?source,
    });
  }

  Future<void> logRewardedAdCompleted({String? placement, String? source}) {
    return logEvent(AnalyticsConfig.eventRewardedAdCompleted, {
      'placement': ?placement,
      'source': ?source,
    });
  }

  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    if (!_config.enabled || !_ready) return;
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(
        name: name,
        parameters: parameters == null ? null : _sanitize(parameters),
      );
    } catch (error, stack) {
      debugPrint('[Analytics] event "$name" failed: $error\n$stack');
    }
  }

  Map<String, Object> _sanitize(Map<String, Object> parameters) {
    const blocked = {
      'password',
      'email',
      'phone',
      'token',
      'auth',
      'payment',
      'card',
    };
    final out = <String, Object>{};
    for (final entry in parameters.entries) {
      final key = entry.key.toLowerCase();
      if (blocked.any(key.contains)) continue;
      final value = entry.value;
      if (value is String || value is num || value is bool) {
        out[entry.key] = value;
      } else {
        out[entry.key] = value.toString();
      }
    }
    return out;
  }
}
