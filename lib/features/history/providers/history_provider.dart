import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/supabase_client.dart';
import '../../../models/checkin_model.dart';
import '../../auth/providers/current_user_provider.dart';

part 'history_provider.g.dart';

/// How many rows the timeline pulls. A paired couple writes up to two rows a
/// day, so this covers roughly three months of history.
const int kHistoryPageSize = 180;

@riverpod
Future<List<CheckinModel>> historyCheckins(HistoryCheckinsRef ref) async {
  final profile = await ref.watch(currentUserProvider.future);
  final coupleId = profile?.coupleId;
  if (coupleId == null) return [];

  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('daily_checkins')
      .select()
      .eq('couple_id', coupleId)
      .order('created_at', ascending: false)
      .limit(kHistoryPageSize);

  return (response as List)
      .map((json) => CheckinModel.fromJson(json as Map<String, dynamic>))
      .toList();
}

/// Current and longest run of consecutive days on which the couple checked in.
///
/// Extracted from the provider so it can be unit tested without a Supabase
/// client. [today] is injectable for the same reason.
///
/// A day counts if *either* partner checked in, which matches how the
/// `trg_update_streak` database trigger maintains `streaks.current_streak`.
Map<String, int> calculateStreak(
  Iterable<DateTime> checkinTimestamps, {
  DateTime? today,
}) {
  DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  final days = checkinTimestamps.map((d) => dayOf(d.toLocal())).toSet().toList()
    ..sort((a, b) => b.compareTo(a));

  if (days.isEmpty) return {'current': 0, 'longest': 0};

  final todayMidnight = dayOf(today ?? DateTime.now());

  // Step by calendar date rather than subtracting DateTimes: across a
  // daylight-saving boundary two adjacent days are 23 or 25 hours apart and
  // Duration.inDays reports the wrong number for the same gap. The DateTime
  // constructor normalises an overflowing day, so this handles month and year
  // boundaries too.
  bool isDayBefore(DateTime later, DateTime earlier) =>
      DateTime(earlier.year, earlier.month, earlier.day + 1) == later;

  var longest = 1;
  var run = 1;
  for (var i = 1; i < days.length; i++) {
    run = isDayBefore(days[i - 1], days[i]) ? run + 1 : 1;
    if (run > longest) longest = run;
  }

  // The current streak only exists if the most recent check-in is today or
  // yesterday; otherwise it has already lapsed. Crucially it stops at the
  // first gap -- the previous implementation resumed counting across gaps.
  var current = 0;
  final mostRecent = days.first;
  if (mostRecent == todayMidnight || isDayBefore(todayMidnight, mostRecent)) {
    current = 1;
    for (var i = 1; i < days.length; i++) {
      if (!isDayBefore(days[i - 1], days[i])) break;
      current++;
    }
  }

  return {'current': current, 'longest': longest};
}

@riverpod
Future<Map<String, int>> syncStreak(SyncStreakRef ref) async {
  final checkins = await ref.watch(historyCheckinsProvider.future);
  return calculateStreak(checkins.map((c) => c.createdAt));
}
