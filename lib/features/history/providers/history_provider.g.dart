// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$historyCheckinsHash() => r'fd9bbc0e20b2cf1639357ab0046ad8f0b3840c64';

/// See also [historyCheckins].
@ProviderFor(historyCheckins)
final historyCheckinsProvider =
    AutoDisposeFutureProvider<List<CheckinModel>>.internal(
  historyCheckins,
  name: r'historyCheckinsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$historyCheckinsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HistoryCheckinsRef = AutoDisposeFutureProviderRef<List<CheckinModel>>;
String _$syncStreakHash() => r'62da5166c25592226f3d03a21cf274369c8a8b25';

/// See also [syncStreak].
@ProviderFor(syncStreak)
final syncStreakProvider = AutoDisposeFutureProvider<Map<String, int>>.internal(
  syncStreak,
  name: r'syncStreakProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncStreakHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncStreakRef = AutoDisposeFutureProviderRef<Map<String, int>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
