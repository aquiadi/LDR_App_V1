import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/mood_catalog.dart';
import '../../../shared/widgets/ambient_background.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../auth/providers/partner_provider.dart';
import '../../checkin/providers/checkin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../history/providers/history_provider.dart';
import '../providers/presence_provider.dart';
import '../providers/ping_provider.dart';
import '../providers/prompt_provider.dart';
import '../providers/countdown_provider.dart';
import '../../../models/checkin_model.dart';
import '../../../models/user_model.dart';

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
    final currentPrompt = ref.watch(dailyPromptProvider);
    final countdownAsync = ref.watch(nextCountdownProvider);
    
    // Initialize presence tracking for this user
    ref.watch(presenceControllerProvider);

    final isPartnerOnline = ref.watch(partnerPresenceStreamProvider).valueOrNull ?? false;
    final isPingCooldown = ref.watch(pingControllerProvider);

    // Listen to incoming pings to show a SnackBar
    ref.listen<AsyncValue<Map<String, dynamic>>>(incomingPingStreamProvider, (previous, next) {
      final data = next.valueOrNull;
      if (data != null && data.isNotEmpty) {
        // Show ping animation or snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.error),
                const SizedBox(width: 12),
                Text("${partnerAsync.valueOrNull?.displayName ?? 'Partner'} is thinking of you!"),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: AppColors.surfaceVariant,
            elevation: 4,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    final user = userAsync.valueOrNull;
    final partner = partnerAsync.valueOrNull;

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildHeader(user),
        body: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(todayCheckinProvider)
              ..invalidate(syncStreakProvider)
              ..invalidate(historyCheckinsProvider)
              ..invalidate(nextCountdownProvider);
            await ref.read(todayCheckinProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
            children: [
              _buildPartnerStatusCard(partner, partnerCheckinAsync, isPartnerOnline),
              const SizedBox(height: 16),
              _buildBentoGrid(todayCheckinAsync, partnerCheckinAsync, partner, streakAsync),
              const SizedBox(height: 16),
              _buildDailyPromptCard(todayCheckinAsync, partnerCheckinAsync, partner, currentPrompt),
              const SizedBox(height: 16),
              _buildInteractionFooter(partner, user?.coupleId, isPingCooldown, ref),
              const SizedBox(height: 16),
              _buildUpcomingMilestone(countdownAsync),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader(UserModel? user) {
    final avatarUrl = user?.avatarUrl;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 24,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
              image: avatarUrl != null && avatarUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(avatarUrl),
                    fit: BoxFit.cover,
                  )
                : null,
            ),
            child: avatarUrl == null || avatarUrl.isEmpty
              ? const Icon(Icons.person_rounded, color: AppColors.outline)
              : null,
          ),
          const SizedBox(width: 12),
          Text('LDR Sync', style: AppTypography.headlineMd.copyWith(color: AppColors.primary)),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.onSurfaceVariant),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerStatusCard(UserModel? partner,
      AsyncValue<CheckinModel?> partnerCheckinAsync, bool isPartnerOnline) {
    final partnerName = partner?.displayName ?? 'Partner';
    final partnerAvatar = partner?.avatarUrl;
    
    // Format last seen or active status
    String statusText = 'OFFLINE';
    Color statusColor = AppColors.outline;
    
    if (isPartnerOnline) {
      statusText = 'ACTIVE NOW';
      statusColor = AppColors.primary;
    } else if (partner != null && partner.lastSeen != null) {
      final diff = DateTime.now().difference(partner.lastSeen!);
      if (diff.inMinutes < 60) {
        statusText = 'ACTIVE ${diff.inMinutes}M AGO';
      } else if (diff.inHours < 24) {
        statusText = 'ACTIVE ${diff.inHours}H AGO';
      } else {
        statusText = 'ACTIVE ${diff.inDays}D AGO';
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                  image: partnerAvatar != null && partnerAvatar.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(partnerAvatar),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: partnerAvatar == null || partnerAvatar.isEmpty
                  ? const Icon(Icons.person_rounded, color: AppColors.outline)
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${partnerName.toUpperCase()} • $statusText', style: AppTypography.labelMd.copyWith(color: statusColor, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(partner?.timezone ?? 'Unknown Time', style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionFooter(
      UserModel? partner, String? coupleId, bool isPingCooldown, WidgetRef ref) {
    final canPing = !isPingCooldown && partner != null && coupleId != null;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: !canPing
                ? null
                : () {
                    ref
                        .read(pingControllerProvider.notifier)
                        .sendPing(partner.id, coupleId);
                  },
            icon: isPingCooldown 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.favorite_rounded),
            label: Text(isPingCooldown ? 'Sending...' : 'Thinking of you'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.3),
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoGrid(
      AsyncValue<CheckinModel?> myCheckinAsync,
      AsyncValue<CheckinModel?> partnerCheckinAsync,
      UserModel? partner,
      AsyncValue<Map<String, int>> streakAsync) {
    final streakData = streakAsync.valueOrNull ?? {'current': 0, 'longest': 0};
    
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 32),
                  ),
                ),
                const SizedBox(height: 12),
                Text('${streakData['current']} Days', style: AppTypography.headlineMd.copyWith(color: AppColors.primary)),
                Text('SYNC STREAK', style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
                if (streakData['longest']! > streakData['current']!)
                  Text('Best: ${streakData['longest']}', style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: partnerCheckinAsync.when(
            data: (checkin) {
              if (checkin == null) {
                return _buildEmptyPartnerMood();
              }
              return _buildPartnerMood(checkin, partner);
            },
            loading: () => const GlassCard(child: SizedBox(height: 150, child: Center(child: CircularProgressIndicator()))),
            error: (_, __) => _buildEmptyPartnerMood(),
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerMood(CheckinModel checkin, UserModel? partner) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _buildPartnerCheckinModal(checkin, partner),
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tertiaryContainer.withValues(alpha: 0.2),
              ),
              child: Center(
                child: Icon(moodIconFor(checkin.moodEmoji), color: AppColors.tertiary, size: 32),
              ),
            ),
            const SizedBox(height: 12),
            Text(checkin.moodLabel, style: AppTypography.headlineMd.copyWith(color: AppColors.tertiary)),
            Text("${partner?.displayName?.toUpperCase() ?? 'PARTNER'}'S MOOD", style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCheckinModal(CheckinModel checkin, UserModel? partner) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(32),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.tertiaryContainer.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Icon(moodIconFor(checkin.moodEmoji), color: AppColors.tertiary, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(checkin.moodLabel, style: AppTypography.headlineLg),
                      Text("${partner?.displayName ?? 'Partner'}'s Mood", style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('ENERGY LEVEL', style: AppTypography.labelMd.copyWith(color: AppColors.outline, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: checkin.energyScore / 10,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text('${checkin.energyScore}/10', style: AppTypography.labelMd.copyWith(color: AppColors.primary)),
              ],
            ),
            if (checkin.journalNote != null && checkin.journalNote!.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text('THOUGHTS', style: AppTypography.labelMd.copyWith(color: AppColors.outline, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(checkin.journalNote!, style: AppTypography.bodyLg.copyWith(height: 1.5)),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPartnerMood() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
            ),
            child: const Center(
              child: Icon(Icons.hourglass_empty_rounded, color: AppColors.outline, size: 32),
            ),
          ),
          const SizedBox(height: 12),
          Text('Pending', style: AppTypography.headlineMd.copyWith(color: AppColors.outline)),
          Text('CURRENT MOOD', style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
        ],
      ),
    );
  }

  Widget _buildDailyPromptCard(
    AsyncValue<CheckinModel?> myCheckinAsync,
    AsyncValue<CheckinModel?> partnerCheckinAsync,
    UserModel? partner,
    String currentPrompt,
  ) {
    final bool hasCheckedIn = myCheckinAsync.valueOrNull != null;
    final partnerName = partner?.displayName ?? 'Your partner';
    final partnerAnswered = partnerCheckinAsync.valueOrNull != null;
    final partnerStatus = partnerAnswered
        ? '$partnerName has answered'
        : '$partnerName hasn\'t answered yet';
    
    return GestureDetector(
      onTap: () => context.push('/checkin'),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            SizedBox(
              height: 192,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.35),
                          AppColors.secondary.withValues(alpha: 0.25),
                          AppColors.surface,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.surface,
                          AppColors.surface.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text('DAILY PROMPT', style: AppTypography.labelMd.copyWith(color: Colors.white)),
                        ),
                        const SizedBox(height: 8),
                        Text(currentPrompt, style: AppTypography.headlineMd.copyWith(height: 1.2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: hasCheckedIn ? 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You checked in today. Tap to update your mood or answer.', style: AppTypography.bodyMd),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(partnerStatus,
                              style: AppTypography.bodySm,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Icon(Icons.check_circle_rounded,
                            color: partnerAnswered
                                ? AppColors.primary
                                : AppColors.outline),
                      ],
                    ),
                  ],
                ) :
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'Tap to share your thoughts...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(partnerStatus,
                              style: AppTypography.bodySm,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingMilestone(AsyncValue<CountdownEvent?> countdownAsync) {
    final event = countdownAsync.valueOrNull;
    if (event == null) return const SizedBox.shrink(); // Hide if no event
    
    final diff = event.targetDate.difference(DateTime.now());
    final days = diff.inDays;
    final hours = diff.inHours % 24;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COUNTDOWN', style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
                const SizedBox(height: 4),
                Text(event.title, style: AppTypography.headlineMd),
                Text('In $days Days, $hours Hours', style: AppTypography.bodySm.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$days', style: AppTypography.headlineMd.copyWith(height: 1)),
                Text('DAYS', style: AppTypography.labelMd.copyWith(fontSize: 10, color: AppColors.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
