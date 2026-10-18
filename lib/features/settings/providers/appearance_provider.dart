import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'appearance_provider.g.dart';

/// System, light or dark. Saved on the device, so it survives a restart
/// without a round trip to the server.
@Riverpod(keepAlive: true)
class Appearance extends _$Appearance {
  static const _key = 'appearance';

  /// Loaded once in `main()` so the first frame already has the right theme.
  static SharedPreferences? prefs;

  @override
  ThemeMode build() {
    return switch (prefs?.getString(_key)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      await prefs?.setString(_key, mode.name);
    } catch (_) {
      // Storage can be unavailable (private browsing); the choice still
      // applies for this session.
    }
  }
}
