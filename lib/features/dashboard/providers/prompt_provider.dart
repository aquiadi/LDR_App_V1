import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'prompt_provider.g.dart';

@riverpod
String dailyPrompt(DailyPromptRef ref) {
  final prompts = [
    "What's one thing you miss about our last visit?",
    "What made you smile today?",
    "If we were together right now, what would we be doing?",
    "What's a song that reminds you of us?",
    "What are you most looking forward to when we close the distance?",
    "What's a small detail about me that you love?",
    "Describe your perfect weekend with me.",
    "What's a goal you're working towards right now?",
    "What's something you're grateful for today?",
    "If you could teleport to me for 10 minutes, what would we do?",
  ];

  final daysSinceEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 86400000;
  return prompts[daysSinceEpoch % prompts.length];
}
