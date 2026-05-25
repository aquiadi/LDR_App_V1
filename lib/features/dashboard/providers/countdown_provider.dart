import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/providers/current_user_provider.dart';

part 'countdown_provider.g.dart';

class CountdownEvent {
  final String id;
  final String title;
  final DateTime date;
  
  CountdownEvent({required this.id, required this.title, required this.date});
  
  factory CountdownEvent.fromJson(Map<String, dynamic> json) {
    return CountdownEvent(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
    );
  }
}

@riverpod
Future<CountdownEvent?> nextCountdown(NextCountdownRef ref) async {
  final profile = await ref.watch(currentUserProvider.future);
  if (profile?.coupleId == null) return null;
  
  final supabase = ref.watch(supabaseClientProvider);
  
  final now = DateTime.now().toIso8601String();
  final response = await supabase
      .from('countdown_events')
      .select()
      .eq('couple_id', profile!.coupleId!)
      .gte('date', now)
      .order('date', ascending: true)
      .limit(1)
      .maybeSingle();
      
  if (response == null) return null;
  return CountdownEvent.fromJson(response);
}
