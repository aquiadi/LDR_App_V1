import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_shell.dart';
import '../providers/invite_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/current_couple_provider.dart';
import 'package:go_router/go_router.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
  }

  @override
  void dispose() {
    _glowController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinCouple() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    await ref.read(inviteControllerProvider.notifier).joinCouple(code);
  }



  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inviteState = ref.watch(inviteControllerProvider);
    final currentCoupleAsync = ref.watch(currentCoupleStreamProvider);
    
    final generatedCouple = currentCoupleAsync.valueOrNull ?? inviteState.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 24,
        title: const Wordmark(size: 22),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
            style: TextButton.styleFrom(foregroundColor: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AppCard(
                padding: const EdgeInsets.all(28),
                child: generatedCouple != null
                    ? _buildGeneratedCodeView(generatedCouple.inviteCode, inviteState)
                    : _buildActionSelectionView(inviteState),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionSelectionView(AsyncValue inviteState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Badge(icon: Icons.people_outline_rounded),
        const SizedBox(height: 20),
        Text(
          'Pair with your partner',
          style: AppTypography.headlineLg,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 8-character code your partner sent you, or start a space and send them yours.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        _buildJoinForm(inviteState),

        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            context.push('/onboarding');
          },
          child: const Text('I want to create a space'),
        ),
      ],
    );
  }

  /// Code entry and the Join button. Shown on both views: a user who has
  /// already created a space must still be able to join their partner's
  /// instead, otherwise two people who both tapped "create" could never pair.
  Widget _buildJoinForm(AsyncValue inviteState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomTextField(
          controller: _codeController,
          labelText: 'Invite Code',
          hintText: 'Enter partner\'s 8-character code',
          prefixIcon: Icons.key_rounded,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: inviteState.isLoading ? null : _joinCouple,
            child: inviteState.isLoading
                ? SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary))
                : const Text('Join Couple'),
          ),
        ),
        if (inviteState.hasError) ...[
          const SizedBox(height: 16),
          Text(
            _friendlyError(inviteState.error),
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// `Exception('...')` stringifies as "Exception: ...". Show only the message.
  static String _friendlyError(Object? error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  Widget _buildGeneratedCodeView(String code, AsyncValue inviteState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Badge(icon: Icons.mark_email_unread_outlined),
        const SizedBox(height: 20),
        Text(
          'Your space is ready',
          style: AppTypography.headlineLg,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Send this code to your partner. As soon as they enter it, you'll both land on your dashboard.",
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SelectableText(
                code,
                style: AppTypography.buttonText.copyWith(
                  fontSize: 28,
                  letterSpacing: 6,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              TextButton.icon(
                onPressed: () => _copyToClipboard(code),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Wait for partner indicator
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: 0.5 + (_glowController.value * 0.5),
                  child: SizedBox(
                    height: 16, width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Opacity(
                  opacity: 0.5 + (_glowController.value * 0.5),
                  child: Text('Waiting for your partner to join', style: AppTypography.bodySmall),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          'Got a code from your partner instead?',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _buildJoinForm(inviteState),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  const _Badge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
      child: Icon(icon, color: AppColors.primary, size: 26),
    );
  }
}
