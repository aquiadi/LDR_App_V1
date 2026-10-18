import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/responsive.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  /// Opens on the sign-up form, e.g. from the landing page's
  /// "Create your space" button (`/login?mode=signup`).
  final bool startWithSignUp;

  const LoginScreen({super.key, this.startWithSignUp = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _isSignUp = widget.startWithSignUp;
  bool _obscurePassword = true;
  String? _notice;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) return;
    setState(() => _notice = null);

    final controller = ref.read(authControllerProvider.notifier);
    if (_isSignUp) {
      await controller.signUp(email: email, password: password);
      // With "Confirm email" on, sign-up succeeds without a session and the
      // router stays here. Say so, instead of leaving the form looking idle.
      final noSession = ref.read(supabaseClientProvider).auth.currentSession == null;
      if (mounted && !ref.read(authControllerProvider).hasError && noSession) {
        setState(() => _notice = 'Check $email for a confirmation link, then log in.');
      }
    } else {
      await controller.signIn(email: email, password: password);
    }
  }

  static String _friendlyError(Object? error) {
    if (error is AuthException) return error.message;
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  @override
  Widget build(BuildContext context) {
    final form = _buildForm();

    if (!Breakpoints.isExpanded(context)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: form,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const Expanded(child: _BrandPanel()),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: form,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final authState = ref.watch(authControllerProvider);
    final wide = Breakpoints.isExpanded(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!wide) ...[
          const Wordmark(size: 24),
          const SizedBox(height: 40),
        ],
        Text(
          _isSignUp ? 'Create your account' : 'Welcome back',
          style: AppTypography.headlineLg,
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUp
              ? 'Make an account, then start a space or join your partner\'s.'
              : 'Log in to see how their day went.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'Enter your email',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          labelText: 'Password',
          hintText: 'Enter your password',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        if (authState.hasError) ...[
          const SizedBox(height: 16),
          _Message(text: _friendlyError(authState.error), isError: true),
        ] else if (_notice != null) ...[
          const SizedBox(height: 16),
          _Message(text: _notice!, isError: false),
        ],
        const SizedBox(height: 28),
        PrimaryButton(
          text: _isSignUp ? 'Sign Up' : 'Log In',
          isLoading: authState.isLoading,
          onPressed: _submit,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _isSignUp = !_isSignUp;
              _notice = null;
            }),
            child: Text(
              _isSignUp ? 'Already have an account? Log in' : 'Don\'t have an account? Sign up',
            ),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final bool isError;

  const _Message({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorContainer : AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTypography.bodySm.copyWith(
          color: isError ? AppColors.onErrorContainer : AppColors.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// Left half of the wide login layout: the evening sky, and the idea of the
/// app in one sentence.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: SkyPalette.forHour(21)),
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultTextStyle.merge(
            style: const TextStyle(color: SkyPalette.inkOnDark),
            child: const _LightWordmark(),
          ),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Two time zones.\nOne small ritual, '),
                  TextSpan(
                    text: 'every day.',
                    style: AppTypography.accent.copyWith(color: const Color(0xffC9BEFF)),
                  ),
                ],
              ),
              style: AppTypography.display.copyWith(color: SkyPalette.inkOnDark, fontSize: 44),
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              'Tell each other how the day actually went: a mood, your energy, '
              'one honest line. It lands on their screen the moment you send it.',
              style: AppTypography.bodyLg.copyWith(color: SkyPalette.inkOnDark.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LightWordmark extends StatelessWidget {
  const _LightWordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xffA79BFF), shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xffFF7FA8), shape: BoxShape.circle)),
        const SizedBox(width: 9),
        Text('LDR Sync', style: AppTypography.headlineMd.copyWith(fontSize: 22, height: 1, color: SkyPalette.inkOnDark)),
      ],
    );
  }
}
