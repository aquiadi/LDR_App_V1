import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/ambient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../auth/providers/current_couple_provider.dart';
import '../../auth/providers/partner_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/app_router.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(settingsControllerProvider);
    final userAsync = ref.watch(currentUserProvider);
    final partnerAsync = ref.watch(partnerStreamProvider);
    final coupleAsync = ref.watch(currentCoupleStreamProvider);

    final user = userAsync.valueOrNull;
    final partner = partnerAsync.valueOrNull;
    final couple = coupleAsync.valueOrNull;

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Us', style: AppTypography.headlineLgMobile),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
          children: [
            _buildAvatarHeader(user, partner, couple),
            const SizedBox(height: 32),
            _buildSectionHeader('YOUR RELATIONSHIP'),
            _buildSettingsGroup(
              children: [
                _buildSettingsRow(
                  icon: Icons.calendar_today_rounded,
                  title: 'Anniversary',
                  value: couple?.anniversaryDate == null
                      ? 'Not set'
                      : DateFormat.yMMMMd().format(couple!.anniversaryDate!),
                ),
                _buildDivider(),
                _buildSettingsRow(
                  icon: Icons.location_on_rounded,
                  title: '${partner?.displayName ?? 'Partner'}\'s Timezone',
                  value: partner?.timezone ?? 'Unknown',
                ),
                _buildDivider(),
                _buildSettingsRow(
                  icon: Icons.access_time_rounded,
                  title: 'Your Timezone',
                  value: user?.timezone ?? 'Unknown',
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('APP PREFERENCES'),
            _buildSettingsGroup(
              children: [
                _buildSwitchRow(
                  icon: Icons.notifications_active_rounded,
                  title: 'Push Notifications',
                  value: prefs.pushNotifications,
                  onChanged: (v) => ref.read(settingsControllerProvider.notifier).togglePushNotifications(v),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  icon: Icons.vibration_rounded,
                  title: 'Haptic Feedback',
                  value: prefs.hapticFeedback,
                  onChanged: (v) => ref.read(settingsControllerProvider.notifier).toggleHapticFeedback(v),
                ),
                _buildDivider(),
                _buildSettingsRow(
                  icon: Icons.palette_rounded,
                  title: 'Theme',
                  value: 'System Default',
                  showChevron: true,
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('ACCOUNT'),
            _buildSettingsGroup(
              children: [
                _buildSettingsRow(
                  icon: Icons.person_rounded,
                  title: 'Account Details',
                  showChevron: true,
                  onTap: () => context.push(AppRoutes.editProfile),
                ),
                _buildDivider(),
                _buildSettingsRow(
                  icon: Icons.privacy_tip_rounded,
                  title: 'Privacy & Security',
                  showChevron: true,
                ),
                _buildDivider(),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: Text('Sign Out', style: AppTypography.bodyLg.copyWith(color: AppColors.error)),
                  onTap: () {
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarHeader(user, partner, couple) {
    final userName = user?.displayName ?? 'You';
    final partnerName = partner?.displayName ?? 'Partner';
    
    // Simple duration calc for MVP
    final String connectionDuration = couple?.createdAt != null 
      ? 'Connected since ${couple!.createdAt.year}'
      : 'Connected recently';

    return Column(
      children: [
        SizedBox(
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Connector Line
              Positioned(
                left: 60,
                right: 60,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
              // You
              Positioned(
                left: 0,
                child: _buildAvatar(user?.avatarUrl),
              ),
              // Heart icon in middle
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.favorite_rounded, color: AppColors.primaryContainer, size: 20),
              ),
              // Partner
              Positioned(
                right: 0,
                child: _buildAvatar(partner?.avatarUrl),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('$userName & $partnerName', style: AppTypography.headlineLgMobile),
        const SizedBox(height: 4),
        Text(connectionDuration, style: AppTypography.bodySm.copyWith(color: AppColors.primary)),
      ],
    );
  }

  Widget _buildAvatar(String? url) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3), width: 3),
        image: url != null && url.isNotEmpty
          ? DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            )
          : null,
      ),
      child: url == null || url.isEmpty
          ? const Icon(Icons.person_rounded, size: 40, color: AppColors.outline)
          : null,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: AppTypography.labelMd.copyWith(color: AppColors.outline, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children}) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    String? value,
    bool showChevron = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: AppColors.onSurfaceVariant),
      title: Text(title, style: AppTypography.bodyLg),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) Text(value, style: AppTypography.bodyMd.copyWith(color: AppColors.outline)),
          if (showChevron) ...[
            if (value != null) const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.outlineVariant),
          ],
        ],
      ),
      onTap: onTap ?? (showChevron ? () {} : null),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: AppColors.onSurfaceVariant),
      title: Text(title, style: AppTypography.bodyLg),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primaryContainer.withValues(alpha: 0.3),
        inactiveThumbColor: AppColors.outline,
        inactiveTrackColor: AppColors.surfaceVariant,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.outlineVariant.withValues(alpha: 0.2),
      indent: 56, // Align with text
    );
  }
}
