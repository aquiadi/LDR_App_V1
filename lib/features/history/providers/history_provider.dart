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
Future<int> syncStreak(SyncStreakRef ref) async {
  final checkins = await ref.watch(historyCheckinsProvider.future);
  if (checkins.isEmpty) return 0;
  
  // Real logic: iterate backward to count consecutive days
  int streak = 0;
  DateTime? lastDate;

  for (final checkin in checkins) {
    // Only count if both checkins are there or just base it on existence.
    // Real implementation would group by day and check if partner also checked in.
    // For MVP, we count consecutive days this user has checked in.
    final currentDay = DateTime(checkin.createdAt.year, checkin.createdAt.month, checkin.createdAt.day);
    
    if (lastDate == null) {
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      
      if (currentDay == todayMidnight || currentDay == todayMidnight.subtract(const Duration(days: 1))) {
        streak++;
        lastDate = currentDay;
      } else {
        break; // Streak broken
      }
    } else {
      final diff = lastDate.difference(currentDay).inDays;
      if (diff == 1) {
        streak++;
        lastDate = currentDay;
      } else if (diff > 1) {
        break; // Streak broken
      }
    }
  }
  
  return streak;
}
