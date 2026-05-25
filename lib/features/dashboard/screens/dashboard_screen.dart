import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/ambient_background.dart';
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

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: RefreshIndicator(
          onRefresh: () async {
            // ignore: unused_result
            ref.refresh(todayCheckinProvider);
          },
          child: ListView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
            children: [
              _buildPartnerStatusCard(partnerCheckinAsync),
              const SizedBox(height: 16),
              _buildBentoGrid(todayCheckinAsync, partnerCheckinAsync),
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

  PreferredSizeWidget _buildAppBar() {
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
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
              image: const DecorationImage(
                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAWm2FK8GqjIhDVUN9ndzE6gbzS2jJvO0FuCf6CK6qNrsX1aGBCbsw2pdaxdHBLRZ_Nvq8bI9avmD5BQoIGuuRWH6Ci4P6Qt54hSexH16jzzrwVbk2lhC2DXFfOSlOPNxJRcUHILifywI0Yv81yCf0iyl4J4RTn-lPAP9DD-sj7m_F9zGBcZq0lfTBUWMb89n9fCiXzb_osbmTm567-YMfEXUMkEdTijPnJ_-J3RiLqJVllvS0MRbEFA3f_Qr6iXJtR_4MDTAUQSORy'),
                fit: BoxFit.cover,
              ),
            ),
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

  Widget _buildPartnerStatusCard(AsyncValue<CheckinModel?> partnerCheckinAsync) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppColors.primaryContainer, blurRadius: 8, spreadRadius: 2)
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('SARAH IS ACTIVE', style: AppTypography.labelMd.copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('London, UK', style: AppTypography.headlineMd),
                  Text('It\'s 10:42 PM there — Late night vibes', style: AppTypography.bodySm),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('56°F', style: AppTypography.headlineMd),
                  Text('Cloudy', style: AppTypography.bodySm),
                ],
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

  Widget _buildBentoGrid(AsyncValue<CheckinModel?> myCheckinAsync, AsyncValue<CheckinModel?> partnerCheckinAsync) {
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
              return _buildPartnerMood(checkin);
            },
            loading: () => const GlassCard(child: SizedBox(height: 150, child: Center(child: CircularProgressIndicator()))),
            error: (_, __) => _buildEmptyPartnerMood(),
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerMood(CheckinModel checkin) {
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
            child: const Center(
              child: Icon(Icons.sentiment_satisfied_rounded, color: AppColors.tertiary, size: 32),
            ),
          ),
          const SizedBox(height: 12),
          Text(checkin.moodLabel, style: AppTypography.headlineMd.copyWith(color: AppColors.tertiary)),
          Text('CURRENT MOOD', style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
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
          Text('Waiting...', style: AppTypography.headlineMd.copyWith(color: AppColors.outline)),
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
