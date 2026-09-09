import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../config/notification_config.dart';
import '../config/test_flags.dart';

typedef NotificationTapCallback = void Function(String? payload);

/// Fully offline local notifications via OS AlarmManager / UNUserNotification.
/// Survives app background + kill. Idempotent. Device-local timezone.
class LocalNotificationService {
  LocalNotificationService({
    NotificationConfig config = const NotificationConfig(),
    FlutterLocalNotificationsPlugin? plugin,
    this.onTap,
  })  : _config = config,
        _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _fingerprintKey = 'local_notification_fingerprint_v1';
  static const _testCount = 5;
  static const _testInterval = Duration(seconds: 10);

  final NotificationConfig _config;
  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationTapCallback? onTap;

  bool _initialized = false;

  Future<void> init() async {
    if (!_config.enabled || _initialized) return;
    try {
      tz_data.initializeTimeZones();
      await _setLocalTimezone();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: (response) {
          onTap?.call(response.payload);
        },
      );
      await _ensureAndroidChannel();
      _initialized = true;
      debugPrint('[LocalNotifications] init ok');
    } catch (error, stack) {
      debugPrint('[LocalNotifications] init failed: $error\n$stack');
    }
  }

  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final androidOk =
          await android?.requestNotificationsPermission() ?? true;
      final iosOk = await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
      debugPrint(
        '[LocalNotifications] permission android=$androidOk ios=$iosOk',
      );
      return androidOk && iosOk;
    } catch (error, stack) {
      debugPrint('[LocalNotifications] permission failed: $error\n$stack');
      return false;
    }
  }

  /// Call after the first UI frame so Android can show the permission dialog.
  Future<int> scheduleNotifications() async {
    if (!_config.enabled) return 0;
    await init();
    if (!_initialized) return 0;

    final allowed = await requestPermission();
    if (!allowed) {
      debugPrint('[LocalNotifications] permission denied — skip schedule');
      return 0;
    }

    try {
      if (TestFlags.notificationTest) {
        await _plugin.cancelAll();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_fingerprintKey);
        final count = await _scheduleTestBurst();
        final pending = await _plugin.pendingNotificationRequests();
        debugPrint(
          '[LocalNotifications] TEST: scheduled=$count '
          'pending=${pending.length} (OS alarms — survives kill)',
        );
        return count;
      }

      final messages = await _loadMessages();
      if (messages.isEmpty) return 0;

      final fingerprint = await _fingerprint(messages);
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_fingerprintKey) == fingerprint) {
        final pending = await _plugin.pendingNotificationRequests();
        if (pending.isNotEmpty) return pending.length;
      }

      await _plugin.cancelAll();
      final count = await _scheduleUpcoming(messages);
      await prefs.setString(_fingerprintKey, fingerprint);
      debugPrint('[LocalNotifications] scheduled $count daily reminders');
      return count;
    } catch (error, stack) {
      debugPrint('[LocalNotifications] schedule failed: $error\n$stack');
      return 0;
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fingerprintKey);
    } catch (error, stack) {
      debugPrint('[LocalNotifications] cancelAll failed: $error\n$stack');
    }
  }

  Future<void> _ensureAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _config.androidChannelId,
        _config.androidChannelName,
        description: 'ShelfSort Master reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  Future<List<NotificationMessage>> _loadMessages() async {
    final raw = await rootBundle.loadString(_config.assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = decoded['notifications'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(NotificationMessage.fromJson)
        .where((m) => m.id.isNotEmpty && m.title.isNotEmpty)
        .toList();
  }

  NotificationDetails _details() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _config.androidChannelId,
        _config.androidChannelName,
        channelDescription: 'ShelfSort Master reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Play-safe: inexact alarms only (no SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM).
  /// Still delivered after kill via ScheduledNotificationReceiver; timing may drift.
  static const _androidScheduleMode =
      AndroidScheduleMode.inexactAllowWhileIdle;

  /// QA: 5 OS-scheduled notifications, every 10s. Works after app kill.
  Future<int> _scheduleTestBurst() async {
    final messages = await _loadMessages();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = 0;

    for (var i = 0; i < _testCount; i++) {
      final fire = now.add(_testInterval * (i + 1));
      final message = messages.isEmpty
          ? NotificationMessage(
              id: 'test_${i + 1}',
              title: 'Test notification ${i + 1}',
              body: 'QA — ${(i + 1) * _testInterval.inSeconds}s (survives kill)',
            )
          : messages[i % messages.length];
      try {
        await _plugin.zonedSchedule(
          id: 9000 + i,
          title: '[TEST ${i + 1}/$_testCount] ${message.title}',
          body: message.body,
          scheduledDate: fire,
          notificationDetails: _details(),
          androidScheduleMode: _androidScheduleMode,
          payload: message.id,
        );
        scheduled++;
        debugPrint(
          '[LocalNotifications] OS schedule id=${9000 + i} at $fire',
        );
      } catch (error, stack) {
        debugPrint(
          '[LocalNotifications] zonedSchedule failed id=${9000 + i}: '
          '$error\n$stack',
        );
      }
    }
    return scheduled;
  }

  Future<int> _scheduleUpcoming(List<NotificationMessage> messages) async {
    var scheduled = 0;
    final now = tz.TZDateTime.now(tz.local);
    for (var day = 0; day < _config.daysToSchedule; day++) {
      final time = _timeForDay(day);
      if (time == null) continue;
      final fire = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      ).add(Duration(days: day));
      if (!fire.isAfter(now)) continue;
      final message = messages[day % messages.length];
      try {
        await _plugin.zonedSchedule(
          id: day + 1,
          title: message.title,
          body: message.body,
          scheduledDate: fire,
          notificationDetails: _details(),
          androidScheduleMode: _androidScheduleMode,
          payload: message.id,
        );
        scheduled++;
      } catch (error, stack) {
        debugPrint(
          '[LocalNotifications] daily schedule failed day=$day: $error\n$stack',
        );
      }
    }
    return scheduled;
  }

  ({int hour, int minute})? _timeForDay(int dayIndex) {
    final times = _config.scheduleTimes;
    if (times.isEmpty) return null;
    final token = _config.rotationMode == NotificationRotationMode.alternate
        ? times[dayIndex % times.length]
        : times[0];
    final parts = token.split(':');
    if (parts.length != 2) return null;
    return (hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _setLocalTimezone() async {
    try {
      final name = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(name));
      debugPrint('[LocalNotifications] timezone=$name');
    } catch (error) {
      debugPrint('[LocalNotifications] timezone fallback UTC: $error');
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<String> _localTimezoneName() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      return 'UTC';
    }
  }

  Future<String> _fingerprint(List<NotificationMessage> messages) async {
    final payload = jsonEncode({
      'tz': await _localTimezoneName(),
      'times': _config.scheduleTimes,
      'mode': _config.rotationMode.name,
      'days': _config.daysToSchedule,
      'messages': messages
          .map((m) => {'id': m.id, 'title': m.title, 'body': m.body})
          .toList(),
    });
    return payload;
  }
}
