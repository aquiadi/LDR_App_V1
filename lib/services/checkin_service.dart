import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/network/supabase_client.dart';
import '../models/checkin_model.dart';

part 'checkin_service.g.dart';

@riverpod
CheckinService checkinService(CheckinServiceRef ref) {
  return CheckinService(ref.watch(supabaseClientProvider));
}

class CheckinService {
  final SupabaseClient _supabase;

  CheckinService(this._supabase);

  Future<CheckinModel?> getTodayCheckin(String coupleId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    // Get start of current day in UTC
    final now = DateTime.now().toUtc();
    final todayStart = DateTime.utc(now.year, now.month, now.day);
    
    final response = await _supabase
        .from('daily_checkins')
        .select()
        .eq('user_id', user.id)
        .eq('couple_id', coupleId)
        .gte('created_at', todayStart.toIso8601String())
        .maybeSingle();

    if (response == null) return null;
    return CheckinModel.fromJson(response);
  }

  Future<CheckinModel> submitCheckin({
    required String coupleId,
    required String moodEmoji,
    required String moodLabel,
    required int affectionScore,
    required int stressScore,
    required int energyScore,
    String? journalNote,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final existingCheckin = await getTodayCheckin(coupleId);
    
    final payload = {
      'user_id': user.id,
      'couple_id': coupleId,
      'mood_emoji': moodEmoji,
      'mood_label': moodLabel,
      'affection_score': affectionScore,
      'stress_score': stressScore,
      'energy_score': energyScore,
      'journal_note': journalNote,
    };

    dynamic response;
    if (existingCheckin != null) {
      response = await _supabase.from('daily_checkins').update(payload).eq('id', existingCheckin.id).select().single();
    } else {
      response = await _supabase.from('daily_checkins').insert(payload).select().single();
    }

    return CheckinModel.fromJson(response);
  }
}
