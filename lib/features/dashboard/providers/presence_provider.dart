import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/providers/current_user_provider.dart';

part 'presence_provider.g.dart';

/// Keeps `users.last_seen` and `users.timezone` fresh while the dashboard is
/// open. This is the coarse fallback the partner card uses when the Presence
/// channel is not live.
///
/// It deliberately does not open a Presence channel itself. Two channels on
/// the same topic cannot coexist: subscribing the second one makes the
/// realtime client leave the first, so whichever one was meant to `track()`
/// never did and nobody ever showed as online. [partnerPresenceStream] owns
/// the one channel and both tracks and listens on it.
@riverpod
class PresenceController extends _$PresenceController {
  Timer? _heartbeatTimer;

  @override
  bool build() {
    final supabase = ref.watch(supabaseClientProvider);
    final profile = ref.watch(currentUserProvider).valueOrNull;

    if (profile == null || profile.coupleId == null) return false;

    _updateLastSeen(supabase, profile.id);
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updateLastSeen(supabase, profile.id);
    });

    ref.onDispose(() {
      _heartbeatTimer?.cancel();
    });

    return true;
  }

  Future<void> _updateLastSeen(SupabaseClient supabase, String userId) async {
    try {
      await supabase.from('users').update({
        // last_seen is timestamptz. A local DateTime serialises with no
        // offset, so Postgres would read it as UTC and the partner would see
        // "active 5h ago" (or a negative number) depending on the zone.
        'last_seen': DateTime.now().toUtc().toIso8601String(),
        'timezone': utcOffsetLabel(DateTime.now().timeZoneOffset),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Error updating last_seen: $e');
    }
  }
}

/// Formats a UTC offset the same way on every platform, e.g. `UTC+05:30`.
///
/// `DateTime.timeZoneName` is not usable for this: it is an abbreviation on
/// some platforms, a long English name on others, and ambiguous either way.
String utcOffsetLabel(Duration offset) {
  if (offset == Duration.zero) return 'UTC';
  final sign = offset.isNegative ? '-' : '+';
  final minutes = offset.inMinutes.abs();
  final hh = (minutes ~/ 60).toString().padLeft(2, '0');
  final mm = (minutes % 60).toString().padLeft(2, '0');
  return 'UTC$sign$hh:$mm';
}

/// Reads a label written by [utcOffsetLabel] back into an offset. Returns
/// null for anything else (older rows hold IANA names or nothing useful).
Duration? parseUtcOffset(String? label) {
  if (label == null) return null;
  if (label == 'UTC') return Duration.zero;
  final m = RegExp(r'^UTC([+-])(\d{2}):(\d{2})$').firstMatch(label);
  if (m == null) return null;
  final minutes = int.parse(m.group(2)!) * 60 + int.parse(m.group(3)!);
  return Duration(minutes: m.group(1) == '-' ? -minutes : minutes);
}

/// Whether the partner currently has the app open, from Supabase Presence.
///
/// One channel per couple: this user tracks themselves on it once the join
/// succeeds, and the sync handler reports whether anyone *else* is present.
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
    var isPartnerOnline = false;

    for (final stateObj in state) {
      for (final presence in stateObj.presences) {
        if (presence.payload['user_id'] != profile.id) {
          isPartnerOnline = true;
          break;
        }
      }
    }
    if (!controller.isClosed) controller.add(isPartnerOnline);
  }).subscribe((status, [error]) async {
    if (status == RealtimeSubscribeStatus.subscribed) {
      await channel.track({
        'user_id': profile.id,
        'online_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  });

  ref.onDispose(() {
    supabase.removeChannel(channel);
    controller.close();
  });

  yield* controller.stream;
}
