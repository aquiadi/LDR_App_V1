// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$partnerCheckinStreamHash() =>
    r'9b853b3d83f61b3eaefad66536beb90000ada812';

/// See also [partnerCheckinStream].
@ProviderFor(partnerCheckinStream)
final partnerCheckinStreamProvider =
    AutoDisposeStreamProvider<CheckinModel?>.internal(
  partnerCheckinStream,
  name: r'partnerCheckinStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$partnerCheckinStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PartnerCheckinStreamRef = AutoDisposeStreamProviderRef<CheckinModel?>;
String _$todayCheckinHash() => r'8fb5c99727718e3d2e03f93994bfe6d17cc8c28a';

/// See also [TodayCheckin].
@ProviderFor(TodayCheckin)
final todayCheckinProvider =
    AutoDisposeAsyncNotifierProvider<TodayCheckin, CheckinModel?>.internal(
  TodayCheckin.new,
  name: r'todayCheckinProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$todayCheckinHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TodayCheckin = AutoDisposeAsyncNotifier<CheckinModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
