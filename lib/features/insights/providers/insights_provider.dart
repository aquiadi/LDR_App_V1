import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/providers/current_user_provider.dart';

part 'insights_provider.g.dart';

@riverpod
Future<Map<String, dynamic>> weeklyInsights(WeeklyInsightsRef ref) async {
  final profile = await ref.watch(currentUserProvider.future);
  if (profile?.coupleId == null) return {};

  // For MVP, we use static data that matches the Stitch design.
  // In a future version, an Edge Function will compute this using OpenAI 
  // based on the last 7 days of check-ins from both partners.
  
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 800));

  return {
    'syncPercentage': 92,
    'trendData': [40.0, 60.0, 55.0, 80.0, 75.0, 90.0, 92.0], // 7 days of sync scores
    'catalystPrompt': "Sarah's been feeling a bit stressed but highly affectionate. Send her a voice note reminding her of your favorite memory together to boost her energy.",
    'tips': [
      {
        'icon': 'chat_bubble_outline',
        'title': 'Communication',
        'desc': 'You both thrive on evening check-ins. Keep it up!',
      },
      {
        'icon': 'favorite_border',
        'title': 'Affection',
        'desc': 'Try sending a surprise message tomorrow morning.',
      }
    ]
  };
}
