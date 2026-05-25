// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presence_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$partnerPresenceStreamHash() =>
    r'214eb350c496c28068f1f971c115081d2026fcac';

/// See also [partnerPresenceStream].
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
    r'e37f7c44f42a1f2d43f84df318fae4e70a25597e';

/// See also [PresenceController].
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
