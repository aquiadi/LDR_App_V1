import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/checkin_model.dart';
import '../../../services/checkin_service.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../auth/providers/current_couple_provider.dart';
import '../../history/providers/history_provider.dart';
import '../../../core/network/supabase_client.dart';

part 'checkin_provider.g.dart';

@riverpod
class TodayCheckin extends _$TodayCheckin {
  @override
  FutureOr<CheckinModel?> build() async {
    final profile = await ref.watch(currentUserProvider.future);
    if (profile?.coupleId == null) return null;
    
    final service = ref.watch(checkinServiceProvider);
    return service.getTodayCheckin(profile!.coupleId!);
  }

  Future<void> submitCheckin({
    required String moodEmoji,
    required String moodLabel,
    required int affectionScore,
    required int stressScore,
    required int energyScore,
    String? journalNote,
  }) async {
    final profile = await ref.read(currentUserProvider.future);
    if (profile?.coupleId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(checkinServiceProvider);
      return service.submitCheckin(
        coupleId: profile!.coupleId!,
        moodEmoji: moodEmoji,
        moodLabel: moodLabel,
        affectionScore: affectionScore,
        stressScore: stressScore,
        energyScore: energyScore,
        journalNote: journalNote,
      );
    });

    // The streak and the Journey timeline are derived from this list. The
    // dashboard stays mounted under the pushed check-in route, so without
    // this they keep showing the count from before the check-in.
    if (!state.hasError) ref.invalidate(historyCheckinsProvider);
  }
}

@riverpod
Stream<CheckinModel?> partnerCheckinStream(PartnerCheckinStreamRef ref) async* {
  final profile = await ref.watch(currentUserProvider.future);
  final couple = await ref.watch(currentCoupleStreamProvider.future);
  
  if (profile?.coupleId == null || couple == null) {
    yield null;
    return;
  }

  // Find partner's ID
  final partnerId = profile!.id == couple.partner1Id ? couple.partner2Id : couple.partner1Id;
  if (partnerId == null) {
    yield null;
    return;
  }

  final supabase = ref.watch(supabaseClientProvider);
  
  // Realtime stream of the partner's check-in for *today*. Without the date
  // filter this returned their newest row ever, so from their first check-in
  // onwards the dashboard said they had answered every single day.
  //
  // "Today" is the UTC day, the same boundary the one-per-day unique index
  // and getTodayCheckin use.
  yield* supabase
      .from('daily_checkins')
      .stream(primaryKey: ['id'])
      .eq('couple_id', profile.coupleId!)
      .order('created_at', ascending: false)
      .map((events) {
        final now = DateTime.now().toUtc();
        final todayStart = DateTime.utc(now.year, now.month, now.day);
        for (final e in events) {
          if (e['user_id'] != partnerId) continue;
          final createdAt = DateTime.parse(e['created_at'] as String).toUtc();
          if (createdAt.isBefore(todayStart)) continue;
          return CheckinModel.fromJson(e);
        }
        return null;
      });
}
