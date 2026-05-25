import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../../core/network/supabase_client.dart';

part 'insights_provider.g.dart';

@riverpod
Future<Map<String, dynamic>> weeklyInsights(WeeklyInsightsRef ref) async {
  final profile = await ref.watch(currentUserProvider.future);
  if (profile?.coupleId == null) return {};

  try {
    final supabase = ref.read(supabaseClientProvider);
    final response = await supabase.functions.invoke(
      'generate_insights',
      body: {'couple_id': profile!.coupleId!},
    );

    if (response.status == 200 && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
  } catch (e) {
    print('Error fetching insights: $e');
  }

  // Fallback if the function is not deployed or errors out
  return {
    'syncPercentage': 50,
    'trendData': [50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0],
    'catalystPrompt': "Send a voice note to check in with your partner.",
    'tips': [
      {
        'icon': 'chat_bubble_outline',
        'title': 'Communication',
        'desc': 'Share how you are feeling today.',
      }
    ]
  };
}
