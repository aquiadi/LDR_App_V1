import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/providers/current_user_provider.dart';

part 'ping_provider.g.dart';

@riverpod
class PingController extends _$PingController {
  Timer? _cooldownTimer;

  @override
  bool build() {
    ref.onDispose(() {
      _cooldownTimer?.cancel();
    });
    // Returns true if on cooldown, false if ready to ping
    return false;
  }

  Future<void> sendPing(String partnerId, String coupleId) async {
    if (state) return; // On cooldown

    final supabase = ref.read(supabaseClientProvider);
    final profile = ref.read(currentUserProvider).valueOrNull;
    if (profile == null) return;

    try {
      // Set cooldown state immediately for UI feedback
      state = true;
      
      await supabase.from('relationship_pings').insert({
        'sender_id': profile.id,
        'receiver_id': partnerId,
        'couple_id': coupleId,
      });

      // 60-second cooldown
      _cooldownTimer = Timer(const Duration(seconds: 60), () {
        state = false;
      });
    } catch (e) {
      // Revert cooldown on error
      state = false;
      debugPrint('Error sending ping: $e');
    }
  }
}

// Stream to listen to incoming pings
@riverpod
Stream<Map<String, dynamic>> incomingPingStream(IncomingPingStreamRef ref) async* {
  final supabase = ref.watch(supabaseClientProvider);
  final profile = ref.watch(currentUserProvider).valueOrNull;

  if (profile == null) {
    yield* const Stream.empty();
    return;
  }

  // Yield empty first to initialize stream
  yield {};

  final controller = StreamController<Map<String, dynamic>>();

  final channel = supabase.channel('public:relationship_pings:receiver_id=eq.${profile.id}');
  
  channel.onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'relationship_pings',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'receiver_id',
      value: profile.id,
    ),
    callback: (payload) {
      controller.add(payload.newRecord);
    },
  ).subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  yield* controller.stream;
}
