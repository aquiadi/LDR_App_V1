// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appearance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appearanceHash() => r'0ba86808a6f6739550e846eeef7e302409f6700d';

/// System, light or dark. Saved on the device, so it survives a restart
/// without a round trip to the server.
///
/// Copied from [Appearance].
@ProviderFor(Appearance)
final appearanceProvider = NotifierProvider<Appearance, ThemeMode>.internal(
  Appearance.new,
  name: r'appearanceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appearanceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Appearance = Notifier<ThemeMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
