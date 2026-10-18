import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/checkin_model.dart';
import '../../../models/user_model.dart';
import '../../../shared/mood_catalog.dart';
import '../../../shared/widgets/ambient_background.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../auth/providers/partner_provider.dart';
import '../../checkin/providers/checkin_provider.dart';
import '../../history/providers/history_provider.dart';
import '../providers/countdown_provider.dart';
import '../providers/ping_provider.dart';
import '../providers/presence_provider.dart';
import '../providers/prompt_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final todayCheckinAsync = ref.watch(todayCheckinProvider);
    final partnerCheckinAsync = ref.watch(partnerCheckinStreamProvider);
    final partnerAsync = ref.watch(partnerStreamProvider);
    final userAsync = ref.watch(currentUserProvider);
    final streakAsync = ref.watch(syncStreakProvider);
    final historyAsync = ref.watch(historyCheckinsProvider);
    final currentPrompt = ref.watch(dailyPromptProvider);
    final countdownAsync = ref.watch(nextCountdownProvider);

    // Keeps last_seen and the time zone fresh while this screen is open.
    ref.watch(presenceControllerProvider);

    final isPartnerOnline = ref.watch(partnerPresenceStreamProvider).valueOrNull ?? false;
    final isPingCooldown = ref.watch(pingControllerProvider);

    // The streak counts the partner's check-ins too, so refetch the history
    // it is computed from when one arrives over realtime. Skips the stream's
    // first load (no previous value), which would only refetch what
    // syncStreak is already fetching.
    ref.listen<AsyncValue<CheckinModel?>>(partnerCheckinStreamProvider, (previous, next) {
      if (previous == null || !previous.hasValue) return;
      final after = next.valueOrNull;
      if (after != null && after.id != previous.valueOrNull?.id) {
        ref.invalidate(historyCheckinsProvider);
      }
    });

    ref.listen<AsyncValue<Map<String, dynamic>>>(incomingPingStreamProvider, (previous, next) {
      final data = next.valueOrNull;
      if (data != null && data.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.inversePrimary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text("${partnerAsync.valueOrNull?.displayName ?? 'Your partner'} is thinking of you"),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    final user = userAsync.valueOrNull;
    final partner = partnerAsync.valueOrNull;
    final myCheckin = todayCheckinAsync.valueOrNull;
    final partnerCheckin = partnerCheckinAsync.valueOrNull;
    final streak = streakAsync.valueOrNull ?? const {'current': 0, 'longest': 0};

    final partnerCard = _PartnerSkyCard(partner: partner, online: isPartnerOnline);
    final todayRow = _TodayRow(
      me: myCheckin,
      partner: partnerCheckin,
      partnerName: partner?.displayName ?? 'Your partner',
      onCheckIn: () => context.push(AppRoutes.checkin),
      onOpenPartner: partnerCheckin == null ? null : () => _showCheckin(partnerCheckin, partner),
    );
    final nudge = _NudgeButton(
      enabled: !isPingCooldown && partner != null && user?.coupleId != null,
      coolingDown: isPingCooldown,
      partnerName: partner?.displayName,
      onPressed: () => ref.read(pingControllerProvider.notifier).sendPing(partner!.id, user!.coupleId!),
    );
    final streakCard = _StreakCard(
      current: streak['current'] ?? 0,
      longest: streak['longest'] ?? 0,
      history: historyAsync.valueOrNull ?? const [],
    );
    final promptCard = _PromptCard(
      prompt: currentPrompt,
      answered: myCheckin != null,
      partnerAnswered: partnerCheckin != null,
      partnerName: partner?.displayName ?? 'Your partner',
      onTap: () => context.push(AppRoutes.checkin),
    );
    final countdown = countdownAsync.valueOrNull;
    final countdownCard = countdown == null ? null : _CountdownCard(event: countdown);

    return AmbientBackground(
      child: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(todayCheckinProvider)
            ..invalidate(syncStreakProvider)
            ..invalidate(historyCheckinsProvider)
            ..invalidate(nextCountdownProvider);
          await ref.read(todayCheckinProvider.future);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 760;
            const gap = SizedBox(height: 16);
            final header = _Header(name: user?.displayName);

            final body = twoColumns
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(children: [partnerCard, gap, todayRow, gap, nudge]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(children: [
                          streakCard,
                          gap,
                          promptCard,
                          if (countdownCard != null) ...[gap, countdownCard],
                        ]),
                      ),
                    ],
                  )
                : Column(children: [
                    partnerCard,
                    gap,
                    todayRow,
                    gap,
                    streakCard,
                    gap,
                    promptCard,
                    gap,
                    nudge,
                    if (countdownCard != null) ...[gap, countdownCard],
                  ]);

            return ListView(
              padding: EdgeInsets.fromLTRB(
                Breakpoints.isCompact(context) ? 20 : 32,
                16,
                Breakpoints.isCompact(context) ? 20 : 32,
                32,
              ),
              children: [
                ContentWidth(
                  maxWidth: twoColumns ? 1080 : 640,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [header, const SizedBox(height: 24), body],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showCheckin(CheckinModel checkin, UserModel? partner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _CheckinSheet(checkin: checkin, name: partner?.displayName ?? 'Your partner'),
    );
  }
}

class _Header extends StatelessWidget {
  final String? name;

  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = switch (now.hour) {
      >= 5 && < 12 => 'Good morning',
      >= 12 && < 17 => 'Good afternoon',
      >= 17 && < 22 => 'Good evening',
      _ => 'Hello',
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM').format(now),
                style: AppTypography.bodySm.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: 4),
              Text(
                name == null || name!.isEmpty ? greeting : '$greeting, $name',
                style: AppTypography.headlineLg,
              ),
            ],
          ),
        ),
        if (!Breakpoints.isExpanded(context))
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, color: AppColors.onSurfaceVariant),
            onPressed: () => context.go(AppRoutes.settings),
          ),
      ],
    );
  }
}

/// The partner, under their own sky: the card's colour is the time of day
/// where they are, so "it's 2am for them" needs no reading.
class _PartnerSkyCard extends StatelessWidget {
  final UserModel? partner;
  final bool online;

  const _PartnerSkyCard({required this.partner, required this.online});

  @override
  Widget build(BuildContext context) {
    final offset = parseUtcOffset(partner?.timezone);
    final theirNow = offset == null ? null : DateTime.now().toUtc().add(offset);
    final hour = theirNow?.hour ?? DateTime.now().hour;
    final dark = SkyPalette.isDark(hour);
    final ink = dark ? AppColors.inverseOnSurface : AppColors.onSurface;
    final soft = dark ? AppColors.inverseOnSurface.withValues(alpha: 0.75) : AppColors.onSurfaceVariant;
    final name = partner?.displayName ?? 'Your partner';

    String status;
    if (online) {
      status = 'Here now';
    } else if (partner?.lastSeen != null) {
      final diff = DateTime.now().difference(partner!.lastSeen!);
      status = diff.inMinutes < 1
          ? 'Active just now'
          : diff.inMinutes < 60
              ? 'Active ${diff.inMinutes}m ago'
              : diff.inHours < 24
                  ? 'Active ${diff.inHours}h ago'
                  : 'Active ${diff.inDays}d ago';
    } else {
      status = 'Not seen yet';
    }

    return AppCard(
      gradient: SkyPalette.forHour(hour),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(url: partner?.avatarUrl, name: name, dark: dark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.cardTitle.copyWith(color: ink)),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: online ? const Color(0xff4CAF7A) : soft.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(status, style: AppTypography.bodySm.copyWith(color: soft)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (theirNow != null) ...[
            Text(
              DateFormat('h:mm a').format(theirNow).toLowerCase(),
              style: AppTypography.display.copyWith(color: ink, fontSize: 56, height: 1),
            ),
            const SizedBox(height: 6),
            Text(
              '${SkyPalette.label(hour)} for $name · ${partner!.timezone}',
              style: AppTypography.bodySm.copyWith(color: soft),
            ),
          ] else
            Text(
              "Their local time shows up once they've opened the app.",
              style: AppTypography.bodySm.copyWith(color: soft),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final bool dark;

  const _Avatar({required this.url, required this.name, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dark ? Colors.white.withValues(alpha: 0.15) : AppColors.surfaceContainer,
        image: hasUrl ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover) : null,
      ),
      alignment: Alignment.center,
      child: hasUrl
          ? null
          : Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: AppTypography.cardTitle.copyWith(
                color: dark ? AppColors.inverseOnSurface : AppColors.onSurface,
              ),
            ),
    );
  }
}

/// Today, side by side: your check-in and theirs.
class _TodayRow extends StatelessWidget {
  final CheckinModel? me;
  final CheckinModel? partner;
  final String partnerName;
  final VoidCallback onCheckIn;
  final VoidCallback? onOpenPartner;

  const _TodayRow({
    required this.me,
    required this.partner,
    required this.partnerName,
    required this.onCheckIn,
    required this.onOpenPartner,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MoodTile(
              who: 'You',
              checkin: me,
              accent: AppColors.primary,
              tint: AppColors.primaryContainer,
              emptyText: 'Not checked in yet',
              action: me == null ? 'Check in' : 'Update',
              onTap: onCheckIn,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MoodTile(
              who: partnerName,
              checkin: partner,
              accent: AppColors.secondary,
              tint: AppColors.secondaryContainer,
              emptyText: "Hasn't checked in yet",
              action: partner == null ? null : 'Read',
              onTap: onOpenPartner,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  final String who;
  final CheckinModel? checkin;
  final Color accent;
  final Color tint;
  final String emptyText;
  final String? action;
  final VoidCallback? onTap;

  const _MoodTile({
    required this.who,
    required this.checkin,
    required this.accent,
    required this.tint,
    required this.emptyText,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = checkin;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AppCard(
          raised: false,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(who, style: AppTypography.bodySm.copyWith(color: AppColors.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 14),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c == null ? AppColors.surfaceContainerHigh : tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  c == null ? Icons.more_horiz_rounded : moodIconFor(c.moodEmoji),
                  color: c == null ? AppColors.outline : accent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                c?.moodLabel ?? emptyText,
                style: c == null
                    ? AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)
                    : AppTypography.headlineMd.copyWith(fontSize: 26, height: 1.1),
              ),
              if (c != null) ...[
                const SizedBox(height: 4),
                Text('Energy ${c.energyScore}/10', style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
              ],
              const Spacer(),
              if (action != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(action!, style: AppTypography.bodySm.copyWith(color: accent, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: accent),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The shared streak, with the last seven days as dots so a gap is visible.
class _StreakCard extends StatelessWidget {
  final int current;
  final int longest;
  final List<CheckinModel> history;

  const _StreakCard({required this.current, required this.longest, required this.history});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final days = history.map((c) {
      final u = c.createdAt.toUtc();
      return DateTime.utc(u.year, u.month, u.day);
    }).toSet();

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Streak together', style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$current', style: AppTypography.display.copyWith(fontSize: 56, height: 1)),
              const SizedBox(width: 8),
              Text(current == 1 ? 'day' : 'days', style: AppTypography.bodyLg.copyWith(color: AppColors.onSurfaceVariant)),
              const Spacer(),
              if (longest > 0)
                Text('Best $longest', style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 6; i >= 0; i--)
                _DayDot(
                  label: DateFormat('E').format(today.subtract(Duration(days: i))).substring(0, 1),
                  filled: days.contains(DateTime.utc(today.year, today.month, today.day - i)),
                  isToday: i == 0,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final bool filled;
  final bool isToday;

  const _DayDot({required this.label, required this.filled, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.primary : AppColors.surfaceContainerHigh,
            border: isToday && !filled ? Border.all(color: AppColors.primary, width: 1.5) : null,
          ),
          child: filled ? const Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary) : null,
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.outline, letterSpacing: 0)),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String prompt;
  final bool answered;
  final bool partnerAnswered;
  final String partnerName;
  final VoidCallback onTap;

  const _PromptCard({
    required this.prompt,
    required this.answered,
    required this.partnerAnswered,
    required this.partnerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AppCard(
          color: AppColors.tertiaryContainer,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's question", style: AppTypography.bodySm.copyWith(color: AppColors.onTertiaryContainer.withValues(alpha: 0.7))),
              const SizedBox(height: 10),
              Text(prompt, style: AppTypography.headlineMd.copyWith(color: AppColors.onTertiaryContainer)),
              const SizedBox(height: 18),
              _AnsweredLine(done: answered, text: answered ? 'You answered' : 'Answer it in your check-in'),
              const SizedBox(height: 6),
              _AnsweredLine(
                done: partnerAnswered,
                text: partnerAnswered ? '$partnerName has answered' : "$partnerName hasn't answered yet",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnsweredLine extends StatelessWidget {
  final bool done;
  final String text;

  const _AnsweredLine({required this.done, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: done ? AppColors.success : AppColors.onTertiaryContainer.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: AppTypography.bodySm.copyWith(color: AppColors.onTertiaryContainer)),
        ),
      ],
    );
  }
}

class _NudgeButton extends StatelessWidget {
  final bool enabled;
  final bool coolingDown;
  final String? partnerName;
  final VoidCallback onPressed;

  const _NudgeButton({
    required this.enabled,
    required this.coolingDown,
    required this.partnerName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          coolingDown ? Icons.check_rounded : Icons.favorite_border_rounded,
          color: coolingDown ? AppColors.success : AppColors.primary,
        ),
        label: Text(
          coolingDown ? 'Sent. You can send another in a minute' : 'Thinking of you',
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceContainer,
          minimumSize: const Size(0, 56),
        ),
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final CountdownEvent event;

  const _CountdownCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final diff = event.targetDate.difference(DateTime.now());
    final days = diff.inDays;
    final hours = diff.inHours % 24;

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next time together', style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
                const SizedBox(height: 4),
                Text(event.title, style: AppTypography.cardTitle),
                Text('In $days days, $hours hours', style: AppTypography.bodySm.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          Column(
            children: [
              Text('$days', style: AppTypography.display.copyWith(fontSize: 44, height: 1)),
              Text('days', style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckinSheet extends StatelessWidget {
  final CheckinModel checkin;
  final String name;

  const _CheckinSheet({required this.checkin, required this.name});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(checkin.createdAt.toLocal()).toLowerCase();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$name's check-in · your time $time", style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(moodIconFor(checkin.moodEmoji), color: AppColors.secondary, size: 28),
                ),
                const SizedBox(width: 16),
                Text(checkin.moodLabel, style: AppTypography.headlineLg),
              ],
            ),
            const SizedBox(height: 28),
            Text('Energy', style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: checkin.energyScore / 10,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${checkin.energyScore}/10', style: AppTypography.bodySm),
              ],
            ),
            if (checkin.journalNote != null && checkin.journalNote!.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text('In their words', style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
              const SizedBox(height: 8),
              Text(
                checkin.journalNote!,
                style: AppTypography.headlineMd.copyWith(fontSize: 24, height: 1.3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
