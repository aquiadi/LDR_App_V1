import 'package:flutter_test/flutter_test.dart';
import 'package:ldr_app/features/history/providers/history_provider.dart';

void main() {
  // Fixed reference date keeps these deterministic. Streaks are counted in UTC
  // days, so the fixtures are UTC too and the result does not depend on the
  // time zone of the machine running the tests.
  final today = DateTime.utc(2024, 6, 20);
  DateTime daysAgo(int n) => today.subtract(Duration(days: n));

  group('calculateStreak', () {
    test('no check-ins yields zero', () {
      expect(calculateStreak(const []), {'current': 0, 'longest': 0});
    });

    test('a single check-in today is a one-day streak', () {
      expect(calculateStreak([today], today: today), {'current': 1, 'longest': 1});
    });

    test('counts consecutive days back from today', () {
      final result = calculateStreak(
        [daysAgo(0), daysAgo(1), daysAgo(2)],
        today: today,
      );
      expect(result['current'], 3);
      expect(result['longest'], 3);
    });

    test('both partners on the same day count once', () {
      final result = calculateStreak([
        today.add(const Duration(hours: 9)),
        today.add(const Duration(hours: 21)),
      ], today: today);
      expect(result['current'], 1);
      expect(result['longest'], 1);
    });

    test('a streak ending yesterday is still current', () {
      final result = calculateStreak([daysAgo(1), daysAgo(2)], today: today);
      expect(result['current'], 2);
    });

    test('a streak that lapsed two days ago is no longer current', () {
      final result = calculateStreak([daysAgo(2), daysAgo(3)], today: today);
      expect(result['current'], 0);
      expect(result['longest'], 2);
    });

    // Regression: the previous implementation resumed incrementing the
    // current streak after a gap, because its guard compared a variable
    // against the value it had just been assigned and so was always true.
    test('current streak stops at the first gap', () {
      final result = calculateStreak([
        daysAgo(0), daysAgo(1), // current run of 2
        daysAgo(10), daysAgo(11), daysAgo(12), // older run of 3, after a gap
      ], today: today);
      expect(result['current'], 2, reason: 'must not count across the gap');
      expect(result['longest'], 3);
    });

    test('longest reflects the best historical run, not the current one', () {
      final result = calculateStreak([
        daysAgo(0),
        daysAgo(5), daysAgo(6), daysAgo(7), daysAgo(8),
      ], today: today);
      expect(result['current'], 1);
      expect(result['longest'], 4);
    });

    test('handles month and year boundaries', () {
      final newYear = DateTime.utc(2025, 1, 1);
      final result = calculateStreak([
        newYear,
        DateTime.utc(2024, 12, 31),
        DateTime.utc(2024, 12, 30),
      ], today: newYear);
      expect(result['current'], 3);
    });

    // Regression: days used to be bucketed by the device's local date while
    // the one-per-day rule uses UTC. In UTC-7, Monday's 18:00 check-in is
    // stored on Tuesday (UTC); Tuesday's 16:00 check-in then updates that same
    // row; Wednesday's 16:00 check-in is a new row. Three days in a row, but
    // the local view saw Monday and Wednesday only and reported a streak of 1.
    test('counts UTC days, matching the database', () {
      final result = calculateStreak([
        DateTime.utc(2026, 6, 16, 1), // Mon 18:00 PDT, updated on Tue 16:00
        DateTime.utc(2026, 6, 17, 23), // Wed 16:00 PDT
      ], today: DateTime.utc(2026, 6, 17, 23, 30));
      expect(result['current'], 2);
      expect(result['longest'], 2);
    });

    test('a non-UTC timestamp is bucketed by its UTC date', () {
      // 23:30 at UTC+05:30 on the 20th is 18:00 UTC on the 20th.
      final local = DateTime.parse('2024-06-20T23:30:00+05:30');
      expect(calculateStreak([local], today: today), {'current': 1, 'longest': 1});
    });

    test('unsorted input is handled', () {
      final result = calculateStreak([
        daysAgo(2), daysAgo(0), daysAgo(1),
      ], today: today);
      expect(result['current'], 3);
    });
  });
}
