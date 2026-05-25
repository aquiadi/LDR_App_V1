import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/checkin_model.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../../core/network/supabase_client.dart';

part 'history_provider.g.dart';

@riverpod
Future<List<CheckinModel>> historyCheckins(HistoryCheckinsRef ref) async {
  final profile = await ref.watch(currentUserProvider.future);
  if (profile?.coupleId == null) return [];

  final supabase = ref.watch(supabaseClientProvider);
  
  final response = await supabase
      .from('daily_checkins')
      .select()
      .eq('couple_id', profile!.coupleId!)
      .order('created_at', ascending: false)
      .limit(50); // Fetch last 50 for MVP

  return (response as List).map((json) => CheckinModel.fromJson(json)).toList();
}

@riverpod
Future<Map<String, int>> syncStreak(SyncStreakRef ref) async {
  final checkins = await ref.watch(historyCheckinsProvider.future);
  if (checkins.isEmpty) return {'current': 0, 'longest': 0};
  
  // Group checkins by date (ignoring time)
  final Set<DateTime> checkinDays = {};
  for (final c in checkins) {
    checkinDays.add(DateTime(c.createdAt.year, c.createdAt.month, c.createdAt.day));
  }
  
  final sortedDays = checkinDays.toList()..sort((a, b) => b.compareTo(a));

  int currentStreak = 0;
  int longestStreak = 0;
  int tempStreak = 0;
  DateTime? lastDate;

  final todayMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  for (int i = 0; i < sortedDays.length; i++) {
    final currentDay = sortedDays[i];
    
    if (lastDate == null) {
      if (currentDay == todayMidnight || currentDay == todayMidnight.subtract(const Duration(days: 1))) {
        currentStreak = 1;
        tempStreak = 1;
      } else {
        tempStreak = 1;
      }
    } else {
      final diff = lastDate.difference(currentDay).inDays;
      if (diff == 1) {
        tempStreak++;
        if (currentStreak > 0 && lastDate == sortedDays[i - 1]) {
           currentStreak++;
        }
      } else {
        // Streak broken
        tempStreak = 1; 
      }
    }
    
    if (tempStreak > longestStreak) {
      longestStreak = tempStreak;
    }
    lastDate = currentDay;
  }
  
  return {
    'current': currentStreak,
    'longest': longestStreak,
  };
}
