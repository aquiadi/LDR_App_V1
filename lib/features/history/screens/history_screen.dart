import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/checkin_model.dart';
import '../../../shared/widgets/ambient_background.dart';
import '../../../shared/mood_catalog.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../auth/providers/partner_provider.dart';
import '../providers/history_provider.dart';

/// One calendar day of the couple's shared history.
class _TimelineDay {
  final DateTime day;
  final CheckinModel? mine;
  final CheckinModel? theirs;

  _TimelineDay({required this.day, this.mine, this.theirs});

  bool get isComplete => mine != null && theirs != null;
  bool get isEmpty => mine == null && theirs == null;
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  /// Milestone ladder the streak ring fills towards.
  static int _nextMilestone(int streak) {
    for (final m in const [7, 14, 30, 60, 100, 180, 365]) {
      if (streak < m) return m;
    }
    // Past the last named milestone, keep stepping in years.
    return ((streak ~/ 365) + 1) * 365;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(syncStreakProvider);
    final historyAsync = ref.watch(historyCheckinsProvider);
    final myId = ref.watch(currentUserProvider).valueOrNull?.id;
    final partnerName =
        ref.watch(partnerStreamProvider).valueOrNull?.displayName ?? 'Partner';

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 24,
          title: Text('Our Journey', style: AppTypography.headlineLgMobile),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(historyCheckinsProvider);
            await ref.read(historyCheckinsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
            children: [
              _buildStreakHero(streakAsync),
              const SizedBox(height: 32),
              Text(
                'TIMELINE',
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.outline, letterSpacing: 1.5),
              ),
              const SizedBox(height: 24),
              historyAsync.when(
                data: (checkins) => _buildTimeline(checkins, myId, partnerName),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (e, _) => _buildMessage("Couldn't load your history.\n$e"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakHero(AsyncValue<Map<String, int>> streakAsync) {
    final streak = streakAsync.valueOrNull?['current'] ?? 0;
    final longest = streakAsync.valueOrNull?['longest'] ?? 0;
    final target = _nextMilestone(streak);
    final remaining = target - streak;

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
                  value: target == 0 ? 0 : (streak / target).clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: AppColors.primaryContainer, size: 32),
                  const SizedBox(height: 4),
                  streakAsync.when(
                    data: (s) => Text(
                      '${s['current']}',
                      style: AppTypography.display
                          .copyWith(color: AppColors.primaryContainer, height: 1.1),
                    ),
                    loading: () => const SizedBox(
                        height: 40, width: 40, child: CircularProgressIndicator()),
                    error: (_, __) => const Text('—'),
                  ),
                  Text('DAYS',
                      style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            streak == 0 ? 'Start your streak today' : "You're on a roll!",
            style: AppTypography.headlineMd,
          ),
          const SizedBox(height: 8),
          Text(
            streak == 0
                ? 'Check in today to begin your first streak.'
                : '$remaining more ${remaining == 1 ? 'day' : 'days'} to your '
                    '$target-day milestone.${longest > streak ? ' Best so far: $longest.' : ''}',
            style: AppTypography.bodySm.copyWith(color: AppColors.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Collapses the flat check-in list into one entry per calendar day,
  /// splitting each day's rows into the viewer's and their partner's.
  List<_TimelineDay> _groupByDay(List<CheckinModel> checkins, String? myId) {
    final byDay = <DateTime, List<CheckinModel>>{};
    for (final c in checkins) {
      final local = c.createdAt.toLocal();
      final key = DateTime(local.year, local.month, local.day);
      byDay.putIfAbsent(key, () => []).add(c);
    }

    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return days.map((day) {
      final rows = byDay[day]!;
      return _TimelineDay(
        day: day,
        mine: _firstOrNull(rows.where((c) => c.userId == myId)),
        theirs: _firstOrNull(rows.where((c) => c.userId != myId)),
      );
    }).toList();
  }

  static CheckinModel? _firstOrNull(Iterable<CheckinModel> items) =>
      items.isEmpty ? null : items.first;

  Widget _buildTimeline(List<CheckinModel> checkins, String? myId, String partnerName) {
    if (checkins.isEmpty) {
      return _buildMessage(
        'No check-ins yet.\nYour shared timeline starts with your first one.',
      );
    }

    final days = _groupByDay(checkins, myId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < days.length; i++)
          _buildTimelineItem(
            entry: days[i],
            partnerName: partnerName,
            isFirst: i == 0,
            isLast: i == days.length - 1,
          ),
      ],
    );
  }

  String _labelForDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(day);
    return DateFormat('MMM d, y').format(day);
  }

  Widget _buildTimelineItem({
    required _TimelineDay entry,
    required String partnerName,
    required bool isFirst,
    required bool isLast,
  }) {
    final iconColor = entry.isComplete
        ? AppColors.primary
        : (entry.isEmpty ? AppColors.outline : AppColors.tertiary);

    final subtitle = entry.isComplete
        ? 'You and $partnerName both checked in'
        : entry.mine != null
            ? 'You checked in'
            : entry.theirs != null
                ? '$partnerName checked in'
                : 'No check-ins';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                      width: 2,
                      height: 16,
                      color: AppColors.outline.withValues(alpha: 0.3)),
                Container(
                  width: 16,
                  height: 16,
                  margin: EdgeInsets.only(top: isFirst ? 4 : 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.isEmpty ? Colors.transparent : iconColor,
                    border: Border.all(color: iconColor, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: entry.isComplete
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.outline.withValues(alpha: 0.3),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_labelForDay(entry.day),
                      style: AppTypography.headlineMd.copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
                  if (!entry.isEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDayCard(entry, partnerName),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(_TimelineDay entry, String partnerName) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.mine != null)
                  _moodRow('You', entry.mine!, AppColors.primary),
                if (entry.mine != null && entry.theirs != null)
                  const SizedBox(height: 12),
                if (entry.theirs != null)
                  _moodRow(partnerName, entry.theirs!, AppColors.tertiary),
              ],
            ),
          ),
          if (entry.isComplete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_syncScore(entry.mine!, entry.theirs!)}% Sync',
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.primaryContainer),
              ),
            ),
        ],
      ),
    );
  }

  /// How closely the pair's energy landed on the same day, as a percentage.
  /// A 9-point gap is the widest possible on a 1–10 scale.
  static int _syncScore(CheckinModel a, CheckinModel b) {
    final gap = (a.energyScore - b.energyScore).abs();
    return (100 - (gap / 9 * 100)).round().clamp(0, 100);
  }

  Widget _moodRow(String who, CheckinModel checkin, Color color) {
    return Row(
      children: [
        Icon(moodIconFor(checkin.moodEmoji), color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text('$who: ${checkin.moodLabel}',
              style: AppTypography.bodyMd, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildMessage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
      ),
    );
  }
}
