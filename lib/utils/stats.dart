import '../models/reading.dart';

class Averages {
  final double systolic;
  final double diastolic;
  final double pulse;
  final int count;
  const Averages(this.systolic, this.diastolic, this.pulse, this.count);
}

Averages? averageOf(Iterable<Reading> readings) {
  final list = readings.toList();
  if (list.isEmpty) return null;
  double s = 0, d = 0, p = 0;
  for (final r in list) {
    s += r.systolic;
    d += r.diastolic;
    p += r.pulse;
  }
  final n = list.length;
  return Averages(s / n, d / n, p / n, n);
}

/// Readings taken in the last [days] days (including today).
List<Reading> lastDays(List<Reading> all, int days, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final start = DateTime(n.year, n.month, n.day).subtract(Duration(days: days - 1));
  return all.where((r) => !r.measuredAt.isBefore(start)).toList();
}

/// Consecutive days with at least one reading, ending today.
/// If today has no reading yet, the streak still counts up to yesterday.
int currentStreak(List<Reading> all, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final days = all
      .map((r) => DateTime(r.measuredAt.year, r.measuredAt.month, r.measuredAt.day))
      .toSet();
  var cursor = DateTime(n.year, n.month, n.day);
  if (!days.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return streak;
}

bool hasReadingOn(List<Reading> all, DateTime day) => all.any((r) =>
    r.measuredAt.year == day.year &&
    r.measuredAt.month == day.month &&
    r.measuredAt.day == day.day);
