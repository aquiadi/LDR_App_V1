import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/providers/current_user_provider.dart';

part 'presence_provider.g.dart';

@riverpod
class PresenceController extends _$PresenceController {
  Timer? _heartbeatTimer;

  @override
  bool build() {
    final supabase = ref.watch(supabaseClientProvider);
    final profile = ref.watch(currentUserProvider).valueOrNull;

    if (profile == null || profile.coupleId == null) return false;

    // Supabase Realtime Presence
    final channel = supabase.channel('presence:couple_${profile.coupleId}');

    channel.onPresenceSync((payload) {
      // Intentionally lightweight for now
    }).onPresenceJoin((payload) {
      // Another user joined
    }).onPresenceLeave((payload) {
      // Another user left
    }).subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await channel.track({
          'user_id': profile.id,
          'online_at': DateTime.now().toIso8601String(),
        });
      }
    });

    // Also update `last_seen` in database periodically
    _updateLastSeen(supabase, profile.id);
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updateLastSeen(supabase, profile.id);
    });

    ref.onDispose(() {
      _heartbeatTimer?.cancel();
      channel.unsubscribe();
    });

    return true; // We are tracking presence
  }

  Future<void> _updateLastSeen(dynamic supabase, String userId) async {
    try {
      await supabase.from('users').update({
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      print('Error updating last_seen: $e');
    }
  }
}

// Stream the partner's realtime presence status
@riverpod
Stream<bool> partnerPresenceStream(PartnerPresenceStreamRef ref) async* {
  final supabase = ref.watch(supabaseClientProvider);
  final profile = ref.watch(currentUserProvider).valueOrNull;

  if (profile == null || profile.coupleId == null) {
    yield false;
    return;
  }

  yield false; // Initially offline

  final controller = StreamController<bool>();
  final channel = supabase.channel('presence:couple_${profile.coupleId}');

  channel.onPresenceSync((payload) {
    final state = channel.presenceState();
    bool isPartnerOnline = false;
    
    for (final stateObj in state) {
      for (final presence in stateObj.presences) {
        if (presence.payload['user_id'] != profile.id) {
          isPartnerOnline = true;
          break;
        }
      }
    }
    controller.add(isPartnerOnline);
  }).subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  yield* controller.stream;
}
