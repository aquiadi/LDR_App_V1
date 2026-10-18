import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/supabase_client.dart';
import '../../../models/couple_model.dart';
import 'current_user_provider.dart';

part 'current_couple_provider.g.dart';

@riverpod
Stream<CoupleModel?> currentCoupleStream(CurrentCoupleStreamRef ref) async* {
  final profile = ref.watch(currentUserProvider).valueOrNull;

  if (profile?.coupleId == null) {
    yield null;
    return;
  }

  final supabase = ref.watch(supabaseClientProvider);
  
  // Realtime stream of the specific couple row
  yield* supabase
      .from('couples')
      .stream(primaryKey: ['id'])
      .eq('id', profile!.coupleId!)
      .map((events) {
        if (events.isEmpty) return null;
        return CoupleModel.fromJson(events.first);
      });
}
