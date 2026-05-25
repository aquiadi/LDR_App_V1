import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/glass_card.dart';
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
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.1, end: 0.35).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
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
    
    final generatedCouple = currentCoupleAsync.value ?? inviteState.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Animated Background Glows
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Positioned(
                top: -50,
                left: -50,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: _glowAnimation.value),
                        blurRadius: 150,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Positioned(
                bottom: -100,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: _glowAnimation.value * 0.8),
                        blurRadius: 150,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlassCard(
                  padding: const EdgeInsets.all(32),
                  child: generatedCouple != null
                      ? _buildGeneratedCodeView(generatedCouple.inviteCode)
                      : _buildActionSelectionView(inviteState),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSelectionView(AsyncValue inviteState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.people_rounded,
          size: 48,
          color: AppColors.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Connect with Partner',
          style: AppTypography.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Share your unique invite code or enter your partner\'s code to sync.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // Join couple flow
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
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary))
                : const Text('Join Couple'),
          ),
        ),

        if (inviteState.hasError) ...[
          const SizedBox(height: 16),
          Text(
            inviteState.error.toString(),
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            context.push('/onboarding');
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: Text(
            'I want to create a space',
            style: AppTypography.buttonText,
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratedCodeView(String code) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.celebration_rounded,
          size: 48,
          color: AppColors.secondary,
        ),
        const SizedBox(height: 24),
        Text(
          'Code Generated!',
          style: AppTypography.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Share this code with your partner. Once they enter it, your accounts will be linked.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                code,
                style: AppTypography.h1.copyWith(
                  letterSpacing: 4,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                onPressed: () => _copyToClipboard(code),
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
                  child: const SizedBox(
                    height: 16, width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Opacity(
                  opacity: 0.5 + (_glowController.value * 0.5),
                  child: Text('Waiting for partner to join...', style: AppTypography.bodySmall),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            context.push('/onboarding');
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: Text(
            'Recreate Space (Test)',
            style: AppTypography.buttonText,
          ),
        ),
      ],
    );
  }
}
