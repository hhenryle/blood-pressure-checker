import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ReminderTime {
  final int hour;
  final int minute;
  const ReminderTime(this.hour, this.minute);

  String encode() => '$hour:$minute';
  static ReminderTime decode(String s) {
    final parts = s.split(':');
    return ReminderTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Schedules one-shot local notifications for the next [horizonDays] days.
/// One-shots (rather than a repeating daily alarm) let us skip today's
/// reminders once a reading is logged. The schedule is rebuilt on app start
/// and after every change to readings or reminder times.
class NotificationService {
  static const horizonDays = 14;
  static const maxReminders = 4; // 14 * 4 = 56, under iOS' 64 pending limit

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  /// Returns true if the user granted notification permission.
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    return false;
  }

  /// Fire times for the next [horizonDays] days. Pure, so it is unit-tested.
  /// Skips today's slots when [loggedToday], and any slot already in the past.
  static List<({DateTime when, int id})> plan({
    required DateTime now,
    required List<ReminderTime> times,
    required bool loggedToday,
  }) {
    final limited = times.take(maxReminders).toList();
    final out = <({DateTime when, int id})>[];
    for (var day = 0; day < horizonDays; day++) {
      if (day == 0 && loggedToday) continue;
      for (var i = 0; i < limited.length; i++) {
        final t = limited[i];
        final when = DateTime(now.year, now.month, now.day + day, t.hour, t.minute);
        if (!when.isAfter(now)) continue;
        out.add((when: when, id: day * 10 + i));
      }
    }
    return out;
  }

  Future<void> reschedule({
    required List<ReminderTime> times,
    required bool loggedToday,
  }) async {
    if (!_ready) return;
    await _plugin.cancelAll();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'bp_reminders',
        'Blood pressure reminders',
        channelDescription: 'Daily reminder to log your blood pressure',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final slots = plan(now: DateTime.now(), times: times, loggedToday: loggedToday);
    for (final slot in slots) {
      await _plugin.zonedSchedule(
        slot.id,
        'Time to measure',
        'Log your blood pressure and heart rate.',
        tz.TZDateTime.from(slot.when, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}
