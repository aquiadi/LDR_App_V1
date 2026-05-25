import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

class UserPreferences {
  final bool pushNotifications;
  final bool hapticFeedback;

  UserPreferences({
    this.pushNotifications = true,
    this.hapticFeedback = true,
  });

  UserPreferences copyWith({
    bool? pushNotifications,
    bool? hapticFeedback,
  }) {
    return UserPreferences(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
    );
  }
}

@riverpod
class SettingsController extends _$SettingsController {
  @override
  UserPreferences build() {
    return UserPreferences(); // For MVP, default preferences in-memory
  }

  void togglePushNotifications(bool value) {
    state = state.copyWith(pushNotifications: value);
  }

  void toggleHapticFeedback(bool value) {
    state = state.copyWith(hapticFeedback: value);
  }
}
