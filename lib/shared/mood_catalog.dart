import 'package:flutter/material.dart';

/// A single selectable mood.
///
/// [id] is what gets persisted in `daily_checkins.mood_emoji`. It is a stable
/// token rather than a literal emoji so the icon set can change without
/// rewriting historical rows.
class MoodOption {
  final String id;
  final String label;
  final IconData icon;

  const MoodOption({required this.id, required this.label, required this.icon});
}

/// The canonical mood list. The check-in grid, the dashboard and the history
/// timeline all read from here, so they cannot drift apart.
const List<MoodOption> kMoodOptions = [
  MoodOption(
      id: 'sentiment_very_satisfied',
      label: 'Joyful',
      icon: Icons.sentiment_very_satisfied_rounded),
  MoodOption(id: 'self_improvement', label: 'Calm', icon: Icons.self_improvement_rounded),
  MoodOption(id: 'favorite', label: 'Loved', icon: Icons.favorite_rounded),
  MoodOption(id: 'bedtime', label: 'Sleepy', icon: Icons.bedtime_rounded),
  MoodOption(id: 'distance', label: 'Missing', icon: Icons.social_distance_rounded),
  MoodOption(id: 'cloud', label: 'Gloomy', icon: Icons.cloud_rounded),
];

/// Icon for a persisted mood id, falling back to a neutral face for ids
/// written by an older build of the app.
IconData moodIconFor(String id) {
  for (final m in kMoodOptions) {
    if (m.id == id) return m.icon;
  }
  return Icons.sentiment_satisfied_rounded;
}
