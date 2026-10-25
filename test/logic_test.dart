import 'package:bp_tracker/models/reading.dart';
import 'package:bp_tracker/services/export_service.dart';
import 'package:bp_tracker/services/notification_service.dart';
import 'package:bp_tracker/utils/bp_category.dart';
import 'package:bp_tracker/utils/stats.dart';
import 'package:flutter_test/flutter_test.dart';

Reading r(int s, int d, DateTime t, {int pulse = 70}) =>
    Reading(systolic: s, diastolic: d, pulse: pulse, measuredAt: t);

void main() {
  group('BpCategory.classify', () {
    test('AHA boundaries', () {
      expect(BpCategory.classify(119, 79), BpCategory.normal);
      expect(BpCategory.classify(125, 79), BpCategory.elevated);
      expect(BpCategory.classify(125, 80), BpCategory.stage1);
      expect(BpCategory.classify(135, 70), BpCategory.stage1);
      expect(BpCategory.classify(140, 70), BpCategory.stage2);
      expect(BpCategory.classify(120, 90), BpCategory.stage2);
      expect(BpCategory.classify(181, 90), BpCategory.crisis);
      expect(BpCategory.classify(150, 121), BpCategory.crisis);
    });
  });

  group('stats', () {
    final now = DateTime(2026, 10, 23, 12);

    test('streak counts consecutive days ending today', () {
      final list = [
        r(120, 80, DateTime(2026, 10, 23, 8)),
        r(120, 80, DateTime(2026, 10, 22, 8)),
        r(120, 80, DateTime(2026, 10, 21, 8)),
        r(120, 80, DateTime(2026, 10, 19, 8)),
      ];
      expect(currentStreak(list, now: now), 3);
    });

    test('streak survives a day with no reading yet today', () {
      final list = [r(120, 80, DateTime(2026, 10, 22, 8))];
      expect(currentStreak(list, now: now), 1);
    });

    test('averages', () {
      final a = averageOf([
        r(120, 80, now, pulse: 60),
        r(140, 90, now, pulse: 80),
      ])!;
      expect(a.systolic, 130);
      expect(a.diastolic, 85);
      expect(a.pulse, 70);
      expect(averageOf([]), isNull);
    });

    test('lastDays window includes today and excludes older', () {
      final list = [
        r(120, 80, DateTime(2026, 10, 23, 8)),
        r(120, 80, DateTime(2026, 10, 17, 8)), // 6 days ago, inside 7
        r(120, 80, DateTime(2026, 10, 16, 8)), // 7 days ago, outside
      ];
      expect(lastDays(list, 7, now: now).length, 2);
    });
  });

  group('Reading map round trip', () {
    test('keeps tags and note', () {
      final original = Reading(
        id: 1,
        systolic: 130,
        diastolic: 85,
        pulse: 72,
        measuredAt: DateTime(2026, 10, 23, 8, 30),
        arm: 'left',
        position: 'sitting',
        tags: const ['Stressed', 'After meal'],
        note: 'ok',
      );
      final copy = Reading.fromMap(original.toMap());
      expect(copy.tags, original.tags);
      expect(copy.note, 'ok');
      expect(copy.measuredAt, original.measuredAt);
    });
  });

  test('CSV escapes commas and quotes', () {
    final csv = ExportService.buildCsv([
      Reading(
          systolic: 120,
          diastolic: 80,
          pulse: 60,
          measuredAt: DateTime(2026, 10, 23, 8),
          note: 'felt "dizzy", tired'),
    ]);
    expect(csv, contains('"felt ""dizzy"", tired"'));
  });

  group('reminder plan', () {
    const twice = [ReminderTime(7, 0), ReminderTime(21, 0)];

    test('two a day for 14 days, past slots today are skipped', () {
      // 10:00 -> 07:00 today has passed, 21:00 today has not
      final plan = NotificationService.plan(
          now: DateTime(2026, 10, 24, 10), times: twice, loggedToday: false);
      expect(plan.length, 27);
      expect(plan.first.when, DateTime(2026, 10, 24, 21));
      expect(plan.last.when, DateTime(2026, 11, 6, 21));
    });

    test('logging today drops the rest of today only', () {
      final plan = NotificationService.plan(
          now: DateTime(2026, 10, 24, 10), times: twice, loggedToday: true);
      expect(plan.length, 26);
      expect(plan.first.when, DateTime(2026, 10, 25, 7));
    });

    test('before the first reminder both slots today are kept', () {
      final plan = NotificationService.plan(
          now: DateTime(2026, 10, 24, 6), times: twice, loggedToday: false);
      expect(plan.length, 28);
    });

    test('ids are unique and capped at 4 reminders', () {
      final plan = NotificationService.plan(
        now: DateTime(2026, 10, 24, 0),
        times: const [
          ReminderTime(6, 0), ReminderTime(9, 0), ReminderTime(12, 0),
          ReminderTime(15, 0), ReminderTime(18, 0),
        ],
        loggedToday: false,
      );
      expect(plan.length, 14 * 4); // 56, under iOS' 64 pending limit
      expect(plan.map((s) => s.id).toSet().length, plan.length);
    });

    test('month rollover', () {
      final plan = NotificationService.plan(
          now: DateTime(2026, 10, 30, 22), times: twice, loggedToday: false);
      expect(plan.first.when, DateTime(2026, 10, 31, 7));
    });
  });
}
