// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presence_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$partnerPresenceStreamHash() =>
    r'0eac72d40bf8d8019cb20cdcbc82d1bba16f32b0';

/// Whether the partner currently has the app open, from Supabase Presence.
///
/// One channel per couple: this user tracks themselves on it once the join
/// succeeds, and the sync handler reports whether anyone *else* is present.
///
/// Copied from [partnerPresenceStream].
@ProviderFor(partnerPresenceStream)
final partnerPresenceStreamProvider = AutoDisposeStreamProvider<bool>.internal(
  partnerPresenceStream,
  name: r'partnerPresenceStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$partnerPresenceStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PartnerPresenceStreamRef = AutoDisposeStreamProviderRef<bool>;
String _$presenceControllerHash() =>
    r'71094c3c5a7789beb9025f564df89aed72380633';

/// Keeps `users.last_seen` and `users.timezone` fresh while the dashboard is
/// open. This is the coarse fallback the partner card uses when the Presence
/// channel is not live.
///
/// It deliberately does not open a Presence channel itself. Two channels on
/// the same topic cannot coexist: subscribing the second one makes the
/// realtime client leave the first, so whichever one was meant to `track()`
/// never did and nobody ever showed as online. [partnerPresenceStream] owns
/// the one channel and both tracks and listens on it.
///
/// Copied from [PresenceController].
@ProviderFor(PresenceController)
final presenceControllerProvider =
    AutoDisposeNotifierProvider<PresenceController, bool>.internal(
  PresenceController.new,
  name: r'presenceControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$presenceControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PresenceController = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
