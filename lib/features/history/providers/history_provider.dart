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
  
  // Basic streak calculation: count unique days with at least one checkin
  // moving backwards from today until there's a gap > 1 day.
  // Real implementation would check BOTH partners for a true "sync" streak.
  // For MVP, we'll just return a placeholder or simple logic.
  
  return 14; // Placeholder matching design
}
