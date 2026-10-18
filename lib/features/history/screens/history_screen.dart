import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/checkin_model.dart';
import '../../../shared/widgets/ambient_background.dart';
import '../../../shared/mood_catalog.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive.dart';
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
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(historyCheckinsProvider);
          await ref.read(historyCheckinsProvider.future);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(Breakpoints.isCompact(context) ? 20 : 32, 24, Breakpoints.isCompact(context) ? 20 : 32, 32),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Your journey', style: AppTypography.headlineLg),
                  const SizedBox(height: 4),
                  Text(
                    'Every day either of you checked in, newest first.',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  _buildStreakHero(streakAsync),
                  const SizedBox(height: 36),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStreakHero(AsyncValue<Map<String, int>> streakAsync) {
    final streak = streakAsync.valueOrNull?['current'] ?? 0;
    final longest = streakAsync.valueOrNull?['longest'] ?? 0;
    final target = _nextMilestone(streak);
    final remaining = target - streak;

    return AppCard(
      padding: const EdgeInsets.all(28),
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
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  streakAsync.when(
                    data: (s) => Text(
                      '${s['current']}',
                      style: AppTypography.display
                          .copyWith(color: AppColors.onSurface, fontSize: 56, height: 1),
                    ),
                    loading: () => const SizedBox(
                        height: 40, width: 40, child: CircularProgressIndicator()),
                    error: (_, __) => const Text('—'),
                  ),
                  Text(streak == 1 ? 'day' : 'days',
                      style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            streak == 0 ? 'Start your streak today' : 'Keep it going',
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
    // Compare calendar dates in UTC so a daylight-saving change (a 23 or 25
    // hour local day) cannot turn yesterday into "Today".
    final diff = DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(day.year, day.month, day.day))
        .inDays;
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
        : (entry.isEmpty ? AppColors.outline : AppColors.secondary);

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
    return AppCard(
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
                  _moodRow(partnerName, entry.theirs!, AppColors.secondary),
              ],
            ),
          ),
          if (entry.isComplete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_syncScore(entry.mine!, entry.theirs!)}% Sync',
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.onPrimaryContainer),
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
