// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ping_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$incomingPingStreamHash() =>
    r'e06c15a64f47d6e0d5b7317b85a033f51cccb56d';

/// See also [incomingPingStream].
@ProviderFor(incomingPingStream)
final incomingPingStreamProvider =
    AutoDisposeStreamProvider<Map<String, dynamic>>.internal(
  incomingPingStream,
  name: r'incomingPingStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$incomingPingStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IncomingPingStreamRef
    = AutoDisposeStreamProviderRef<Map<String, dynamic>>;
String _$pingControllerHash() => r'27dfecf24c54a05ead5b9202624aec3d5be5a884';

/// See also [PingController].
@ProviderFor(PingController)
final pingControllerProvider =
    AutoDisposeNotifierProvider<PingController, bool>.internal(
  PingController.new,
  name: r'pingControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pingControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PingController = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
