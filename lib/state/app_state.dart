import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database.dart';
import '../models/reading.dart';
import '../services/notification_service.dart';
import '../utils/stats.dart';

class AppState extends ChangeNotifier {
  AppState(this._db, this._notifications);

  static const _remindersKey = 'reminders';
  static const _defaultReminders = [ReminderTime(7, 0), ReminderTime(21, 0)];

  final AppDatabase _db;
  final NotificationService _notifications;

  List<Reading> readings = [];
  List<ReminderTime> reminders = _defaultReminders;
  bool loading = true;

  bool get loggedToday => hasReadingOn(readings, DateTime.now());
  int get streak => currentStreak(readings);
  Reading? get latest => readings.isEmpty ? null : readings.first;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_remindersKey);
    if (saved != null) reminders = saved.map(ReminderTime.decode).toList();
    readings = await _db.all();
    loading = false;
    notifyListeners();
    // iOS drops scheduled requests until permission is granted, so ask first.
    if (reminders.isNotEmpty) await _notifications.requestPermission();
    await _reschedule();
  }

  Future<void> addReading(Reading r) async {
    await _db.insert(r);
    await _refresh();
  }

  Future<void> updateReading(Reading r) async {
    await _db.update(r);
    await _refresh();
  }

  Future<void> deleteReading(int id) async {
    await _db.delete(id);
    await _refresh();
  }

  Future<void> setReminders(List<ReminderTime> times) async {
    reminders = List.of(times)
      ..sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _remindersKey, reminders.map((t) => t.encode()).toList());
    notifyListeners();
    if (reminders.isNotEmpty) await _notifications.requestPermission();
    await _reschedule();
  }

  Future<void> _refresh() async {
    readings = await _db.all();
    notifyListeners();
    await _reschedule();
  }

  Future<void> _reschedule() => _notifications.reschedule(
        times: reminders,
        loggedToday: loggedToday,
      );
}
