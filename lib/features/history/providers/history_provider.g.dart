// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$historyCheckinsHash() => r'f3c74d8b480c50b3bdc63760b5df3abcd73f1b28';

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
String _$syncStreakHash() => r'57ccd42ef1467677fb7837e6afb58b7098cd552a';

/// See also [syncStreak].
@ProviderFor(syncStreak)
final syncStreakProvider = AutoDisposeFutureProvider<int>.internal(
  syncStreak,
  name: r'syncStreakProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncStreakHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SyncStreakRef = AutoDisposeFutureProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
