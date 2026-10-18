import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/ambient_background.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../auth/providers/current_couple_provider.dart';
import '../../auth/providers/partner_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/app_router.dart';
import '../providers/appearance_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final partnerAsync = ref.watch(partnerStreamProvider);
    final coupleAsync = ref.watch(currentCoupleStreamProvider);

    final user = userAsync.valueOrNull;
    final partner = partnerAsync.valueOrNull;
    final couple = coupleAsync.valueOrNull;

    return AmbientBackground(
      maxWidth: 704,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView(
          padding: EdgeInsets.fromLTRB(Breakpoints.isCompact(context) ? 20 : 32, 24, Breakpoints.isCompact(context) ? 20 : 32, 32),
          children: [
            _buildAvatarHeader(user, partner, couple),
            const SizedBox(height: 32),
            _buildSectionHeader('Your relationship'),
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
                  title: '${partner?.displayName ?? 'Partner'}\'s time zone',
                  value: partner?.timezone ?? 'Unknown',
                ),
                _buildDivider(),
                _buildSettingsRow(
                  icon: Icons.access_time_rounded,
                  title: 'Your time zone',
                  value: user?.timezone ?? 'Unknown',
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Appearance'),
            _buildSettingsGroup(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_outlined)),
                        ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
                      ],
                      selected: {ref.watch(appearanceProvider)},
                      onSelectionChanged: (s) => ref.read(appearanceProvider.notifier).set(s.first),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Account'),
            _buildSettingsGroup(
              children: [
                _buildSettingsRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Account Details',
                  showChevron: true,
                  onTap: () => context.push(AppRoutes.editProfile),
                ),
                _buildDivider(),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Icon(Icons.logout_rounded, color: AppColors.error),
                  title: Text('Sign Out', style: AppTypography.bodyMd.copyWith(color: AppColors.error, fontWeight: FontWeight.w500)),
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
    
    final String connectionDuration = couple?.createdAt != null
      ? 'Together on LDR Sync since ${DateFormat.yMMMM().format(couple!.createdAt)}'
      : 'Together on LDR Sync';

    return Column(
      children: [
        SizedBox(
          width: 260,
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
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Icon(Icons.favorite_rounded, color: AppColors.primary, size: 18),
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
        Text('$userName & $partnerName', style: AppTypography.headlineLg),
        const SizedBox(height: 4),
        Text(connectionDuration, style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
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
          ? Icon(Icons.person_rounded, size: 40, color: AppColors.outline)
          : null,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: AppTypography.bodySm.copyWith(color: AppColors.outline, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children}) {
    return AppCard(
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
      title: Text(title, style: AppTypography.bodyMd),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) Text(value, style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
          if (showChevron) ...[
            if (value != null) const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.outline),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.outlineVariant,
      indent: 56, // Align with text
    );
  }
}
