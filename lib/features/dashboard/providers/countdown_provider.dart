import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/providers/current_user_provider.dart';

part 'countdown_provider.g.dart';

class CountdownEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime targetDate;

  CountdownEvent({
    required this.id,
    required this.title,
    this.description,
    required this.targetDate,
  });

  factory CountdownEvent.fromJson(Map<String, dynamic> json) {
    return CountdownEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetDate: DateTime.parse(json['target_date'] as String),
    );
  }
}

@riverpod
Future<CountdownEvent?> nextCountdown(NextCountdownRef ref) async {
  final profile = await ref.watch(currentUserProvider.future);
  final coupleId = profile?.coupleId;
  if (coupleId == null) return null;

  final supabase = ref.watch(supabaseClientProvider);

  final now = DateTime.now().toUtc().toIso8601String();
  final response = await supabase
      .from('countdown_events')
      .select()
      .eq('couple_id', coupleId)
      .gte('target_date', now)
      .order('target_date', ascending: true)
      .limit(1)
      .maybeSingle();

  if (response == null) return null;
  return CountdownEvent.fromJson(response);
}
