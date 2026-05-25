import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/supabase_client.dart';
import '../../../models/user_model.dart';
import 'current_user_provider.dart';
import 'current_couple_provider.dart';

part 'partner_provider.g.dart';

@riverpod
Stream<UserModel?> partnerStream(PartnerStreamRef ref) async* {
  final coupleAsync = ref.watch(currentCoupleStreamProvider);
  final couple = coupleAsync.value;
  final profileAsync = ref.watch(currentUserProvider);
  final profile = profileAsync.value;

  if (couple == null || profile == null) {
    yield null;
    return;
  }

  // Determine the partner's ID
  String? partnerId;
  if (couple.partner1Id != null && couple.partner1Id != profile.id) {
    partnerId = couple.partner1Id;
  } else if (couple.partner2Id != null && couple.partner2Id != profile.id) {
    partnerId = couple.partner2Id;
  }

  if (partnerId == null) {
    yield null;
    return;
  }

  final supabase = ref.watch(supabaseClientProvider);
  
  // Stream the partner's user profile
  yield* supabase
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('id', partnerId)
      .map((events) {
        if (events.isEmpty) return null;
        return UserModel.fromJson(events.first);
      });
}
