import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/ambient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(syncStreakProvider);

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 24,
          title: Text('Our Journey', style: AppTypography.headlineLgMobile),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(Icons.filter_list_rounded, color: AppColors.onSurfaceVariant),
                onPressed: () {},
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
          children: [
            _buildStreakHero(streakAsync),
            const SizedBox(height: 32),
            _buildTimelineSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakHero(AsyncValue<int> streakAsync) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: 14 / 30, // Example progress to next milestone
                  strokeWidth: 8,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department_rounded, color: AppColors.primaryContainer, size: 32),
                  const SizedBox(height: 4),
                  streakAsync.when(
                    data: (streak) => Text(streak.toString(), style: AppTypography.display.copyWith(color: AppColors.primaryContainer, height: 1.1)),
                    loading: () => const SizedBox(height: 40, width: 40, child: CircularProgressIndicator()),
                    error: (_, __) => const Text('?'),
                  ),
                  Text('DAYS', style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('You\'re on a roll!', style: AppTypography.headlineMd),
          const SizedBox(height: 8),
          Text(
            'Just 16 more days to reach your 1-month milestone. Keep checking in.',
            style: AppTypography.bodySm.copyWith(color: AppColors.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TIMELINE', style: AppTypography.labelMd.copyWith(color: AppColors.outline, letterSpacing: 1.5)),
        const SizedBox(height: 24),
        
        _buildTimelineItem(
          isFirst: true,
          isActive: true,
          title: 'Today',
          subtitle: 'You and Sarah checked in',
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.primary,
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sentiment_very_satisfied_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('You: Joyful', style: AppTypography.bodyMd),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.self_improvement_rounded, color: AppColors.tertiary, size: 20),
                          const SizedBox(width: 8),
                          Text('Sarah: Calm', style: AppTypography.bodyMd),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('92% Sync', style: AppTypography.labelMd.copyWith(color: AppColors.primaryContainer)),
                ),
              ],
            ),
          ),
        ),
        
        _buildTimelineItem(
          isActive: false,
          title: 'Yesterday',
          subtitle: 'You missed your check-in',
          icon: Icons.radio_button_unchecked_rounded,
          iconColor: AppColors.outline,
        ),
        
        _buildTimelineItem(
          isActive: true,
          title: 'Oct 12, 2023',
          subtitle: 'Paris Reunion',
          icon: Icons.flight_land_rounded,
          iconColor: AppColors.secondary,
          isMilestone: true,
        ),
        
        _buildTimelineItem(
          isLast: true,
          isActive: false,
          title: 'Oct 10, 2023',
          subtitle: 'You and Sarah checked in',
          icon: Icons.radio_button_unchecked_rounded,
          iconColor: AppColors.outline,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    bool isFirst = false,
    bool isLast = false,
    required bool isActive,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    bool isMilestone = false,
    Widget? child,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line and Dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!isFirst) 
                  Container(width: 2, height: 16, color: AppColors.outline.withValues(alpha: 0.3)),
                Container(
                  width: isMilestone ? 32 : 16,
                  height: isMilestone ? 32 : 16,
                  margin: EdgeInsets.only(top: isFirst ? 4 : 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMilestone ? iconColor.withValues(alpha: 0.2) : (isActive ? iconColor : Colors.transparent),
                    border: Border.all(color: iconColor, width: 2),
                  ),
                  child: isMilestone ? Icon(icon, size: 16, color: iconColor) : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2, 
                      color: isActive ? AppColors.primary.withValues(alpha: 0.5) : AppColors.outline.withValues(alpha: 0.3),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.headlineMd.copyWith(fontSize: 18, color: isMilestone ? iconColor : null)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
                  if (child != null) ...[
                    const SizedBox(height: 16),
                    child,
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
