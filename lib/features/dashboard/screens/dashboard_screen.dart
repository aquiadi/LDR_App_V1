import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/ambient_background.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../auth/providers/partner_provider.dart';
import '../../auth/providers/current_couple_provider.dart';
import '../../checkin/providers/checkin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/checkin_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _thinkingOfYouActive = false;

  void _triggerThinking() {
    setState(() {
      _thinkingOfYouActive = true;
    });
    
    // In MVP, this is a UI-only animation
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _thinkingOfYouActive = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayCheckinAsync = ref.watch(todayCheckinProvider);
    final partnerCheckinAsync = ref.watch(partnerCheckinStreamProvider);
    final partnerAsync = ref.watch(partnerStreamProvider);
    final userAsync = ref.watch(currentUserProvider);

    final user = userAsync.valueOrNull;
    final partner = partnerAsync.valueOrNull;

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildHeader(user),
        body: RefreshIndicator(
          onRefresh: () async {
            // ignore: unused_result
            ref.refresh(todayCheckinProvider);
          },
          child: ListView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
            children: [
              _buildPartnerStatusCard(partner, partnerCheckinAsync),
              const SizedBox(height: 16),
              _buildBentoGrid(todayCheckinAsync, partnerCheckinAsync, partner),
              const SizedBox(height: 16),
              _buildDailyPromptCard(todayCheckinAsync),
              const SizedBox(height: 16),
              _buildUpcomingMilestone(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader(user) {
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

  Widget _buildPartnerStatusCard(partner, AsyncValue<CheckinModel?> partnerCheckinAsync) {
    final partnerName = partner?.displayName ?? 'Partner';
    final partnerAvatar = partner?.avatarUrl;
    final partnerTime = partner?.timezone ?? 'Unknown Time';

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
                    Text('${partnerName.toUpperCase()} IS ACTIVE', style: AppTypography.labelMd.copyWith(color: AppColors.primary, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text('8:42 PM • $partnerTime', style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _triggerThinking,
              icon: _thinkingOfYouActive 
                  ? const SizedBox.shrink()
                  : const Icon(Icons.favorite_rounded, color: AppColors.onPrimaryContainer),
              label: Text(_thinkingOfYouActive ? 'Sent!' : 'Thinking of you'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(AsyncValue<CheckinModel?> myCheckinAsync, AsyncValue<CheckinModel?> partnerCheckinAsync, partner) {
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
                Text('14 Days', style: AppTypography.headlineMd.copyWith(color: AppColors.primary)),
                Text('SYNC STREAK', style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
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

  IconData _getIconData(String id) {
    switch (id) {
      case 'sentiment_very_satisfied': return Icons.sentiment_very_satisfied_rounded;
      case 'self_improvement': return Icons.self_improvement_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'bedtime': return Icons.bedtime_rounded;
      case 'distance': return Icons.social_distance_rounded;
      case 'cloud': return Icons.cloud_rounded;
      default: return Icons.sentiment_satisfied_rounded;
    }
  }

  Widget _buildPartnerMood(CheckinModel checkin, partner) {
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
              color: AppColors.tertiaryContainer.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Icon(_getIconData(checkin.moodEmoji), color: AppColors.tertiary, size: 32),
            ),
          ),
          const SizedBox(height: 12),
          Text(checkin.moodLabel, style: AppTypography.headlineMd.copyWith(color: AppColors.tertiary)),
          Text("${partner?.displayName?.toUpperCase() ?? 'PARTNER'}'S MOOD", style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
        ],
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

  Widget _buildDailyPromptCard(AsyncValue<CheckinModel?> myCheckinAsync) {
    final bool hasCheckedIn = myCheckinAsync.valueOrNull != null;
    
    return GestureDetector(
      onTap: hasCheckedIn ? null : () => context.push('/checkin'),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            SizedBox(
              height: 192,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: 0.6,
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBJhU7jPgItH1KZ4pQfbyFw1s1vXYky9lNIvgXlDyQ4e7z8YuCQBnnvYxcKxQCXkcSfvLl_N-0P-Lll91XnbGReUhnP1ISGZX7GXqYyA52hE1UwXj5NAN3U0F-Dk0MVWxoK81zi-OanuaJV_oGg7N0cBzPTZjurnnhzA0RJQQy0nqKjbrTn820BOVS7St_-XJlp00GgFFR95uzzWNt9rkdgjEsb3ENomrdd2XFS_oMm77ibGxrI8zCNC7KEjMHwPvybsKN2D5OisiBr',
                      fit: BoxFit.cover,
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
                        Text('What\'s one thing you miss about our last visit?', style: AppTypography.headlineMd.copyWith(height: 1.2)),
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
                    Text('You checked in today. Your partner can now see how you feel.', style: AppTypography.bodyMd),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Waiting for Sarah to answer', style: AppTypography.bodySm),
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary),
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
                        Text('Sarah hasn\'t answered yet', style: AppTypography.bodySm),
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

  Widget _buildUpcomingMilestone() {
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
                Text('Paris Reunion', style: AppTypography.headlineMd),
                Text('In 22 Days, 4 Hours', style: AppTypography.bodySm.copyWith(color: AppColors.primary)),
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
                Text('22', style: AppTypography.headlineMd.copyWith(height: 1)),
                Text('DAYS', style: AppTypography.labelMd.copyWith(fontSize: 10, color: AppColors.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
