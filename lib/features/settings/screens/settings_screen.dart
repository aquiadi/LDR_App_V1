import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/ambient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(settingsControllerProvider);

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
            _buildAvatarHeader(),
            const SizedBox(height: 32),
            _buildSectionHeader('YOUR RELATIONSHIP'),
            _buildSettingsGroup(
              children: [
                _buildSettingsRow(
                  icon: Icons.calendar_today_rounded,
                  title: 'Anniversary',
                  value: 'Oct 14, 2021',
                ),
                _buildDivider(),
                _buildSettingsRow(
                  icon: Icons.location_on_rounded,
                  title: 'Sarah\'s Location',
                  value: 'London, UK',
                ),
                _buildDivider(),
                _buildSettingsRow(
                  icon: Icons.access_time_rounded,
                  title: 'Timezone Difference',
                  value: '+5 Hours',
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

  Widget _buildAvatarHeader() {
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
                child: _buildAvatar(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuA4OzT_GkmKrSjjuD2iNHNPpxOl20CamFvOxiClOcvOE0C-03JkxVYNsFp64zD0_AbPXJTVcJViy1vvHspT_BuBSHEyhouizsPeUfAa_R2Rfh7ie_vmp7N0xLGdeuGHM9COBeuUU7EpvUfqkaFdPIzuMxqcfPxwOK_cecx0K_tO28V1SzN-HHCxnosxYuywvqsc7ihXfeVGA4-Dwfz4VrDjIDY8aeMG9ohARSLmfBIA8kkTGVAO09840mDWymUeIxeRXb2BiJ9tDQmR',
                ),
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
                child: _buildAvatar(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuAWm2FK8GqjIhDVUN9ndzE6gbzS2jJvO0FuCf6CK6qNrsX1aGBCbsw2pdaxdHBLRZ_Nvq8bI9avmD5BQoIGuuRWH6Ci4P6Qt54hSexH16jzzrwVbk2lhC2DXFfOSlOPNxJRcUHILifywI0Yv81yCf0iyl4J4RTn-lPAP9DD-sj7m_F9zGBcZq0lfTBUWMb89n9fCiXzb_osbmTm567-YMfEXUMkEdTijPnJ_-J3RiLqJVllvS0MRbEFA3f_Qr6iXJtR_4MDTAUQSORy',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Alex & Sarah', style: AppTypography.headlineLgMobile),
        const SizedBox(height: 4),
        Text('Connected for 2 years', style: AppTypography.bodySm.copyWith(color: AppColors.primary)),
      ],
    );
  }

  Widget _buildAvatar(String url) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3), width: 3),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
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
      onTap: showChevron ? () {} : null,
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
