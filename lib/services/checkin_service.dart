import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/network/supabase_client.dart';
import '../models/checkin_model.dart';

part 'checkin_service.g.dart';

/// Inclusive bounds of the affection / stress / energy columns, mirroring the
/// `check (… between 1 and 10)` constraints in the database. The UI reads
/// these so the sliders cannot offer a value the database will reject.
const int kMinMoodScore = 1;
const int kMaxMoodScore = 10;

@riverpod
CheckinService checkinService(CheckinServiceRef ref) {
  return CheckinService(ref.watch(supabaseClientProvider));
}

class CheckinService {
  final SupabaseClient _supabase;

  CheckinService(this._supabase);

  /// The signed-in user's check-in for the current UTC day, if any.
  ///
  /// The database enforces one check-in per user per UTC day, but this query
  /// still takes the newest row rather than `.maybeSingle()`: that helper
  /// throws when more than one row comes back, which would turn any legacy
  /// duplicate into a hard failure of the whole check-in screen.
  Future<CheckinModel?> getTodayCheckin(String coupleId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final now = DateTime.now().toUtc();
    final todayStart = DateTime.utc(now.year, now.month, now.day);

    final response = await _supabase
        .from('daily_checkins')
        .select()
        .eq('user_id', user.id)
        .eq('couple_id', coupleId)
        .gte('created_at', todayStart.toIso8601String())
        .order('created_at', ascending: false)
        .limit(1);

    final rows = response as List<dynamic>;
    if (rows.isEmpty) return null;
    return CheckinModel.fromJson(rows.first as Map<String, dynamic>);
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

    final note = journalNote?.trim();
    final payload = {
      'user_id': user.id,
      'couple_id': coupleId,
      'mood_emoji': moodEmoji,
      'mood_label': moodLabel,
      'affection_score': _clampScore(affectionScore),
      'stress_score': _clampScore(stressScore),
      'energy_score': _clampScore(energyScore),
      'journal_note': (note == null || note.isEmpty) ? null : note,
    };

    final Map<String, dynamic> response;
    if (existingCheckin != null) {
      response = await _supabase
          .from('daily_checkins')
          .update(payload)
          .eq('id', existingCheckin.id)
          .select()
          .single();
    } else {
      response = await _supabase
          .from('daily_checkins')
          .insert(payload)
          .select()
          .single();
    }

    return CheckinModel.fromJson(response);
  }

  /// The mood columns carry a `check (… between 1 and 10)` constraint. Clamp
  /// here so an out-of-range value from the UI can never become a failed
  /// insert that the user sees as a silently dropped check-in.
  static int _clampScore(int value) {
    if (value < kMinMoodScore) return kMinMoodScore;
    if (value > kMaxMoodScore) return kMaxMoodScore;
    return value;
  }
}
