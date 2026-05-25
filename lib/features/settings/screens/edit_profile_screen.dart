import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/ambient_background.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/accent_gradient_button.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../../core/network/supabase_client.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        _nameController.text = user.displayName ?? '';
        _avatarUrlController.text = user.avatarUrl ?? '';
      }
    });
    _avatarUrlController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('users').update({
        'display_name': _nameController.text.trim(),
        'avatar_url': _avatarUrlController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // ignore: unused_result
      ref.refresh(currentUserProvider);
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e', style: const TextStyle(color: Colors.white))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Edit Profile', style: AppTypography.headlineLgMobile),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurfaceVariant),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceContainerHigh,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 3),
                          image: _avatarUrlController.text.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(_avatarUrlController.text),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _avatarUrlController.text.isEmpty
                            ? const Icon(Icons.person_rounded, size: 40, color: AppColors.outline)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('DISPLAY NAME', style: AppTypography.labelMd.copyWith(color: AppColors.outline, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _nameController,
                  labelText: '',
                  hintText: 'Enter your name',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 24),
                Text('AVATAR URL', style: AppTypography.labelMd.copyWith(color: AppColors.outline, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _avatarUrlController,
                  labelText: '',
                  hintText: 'https://example.com/avatar.jpg',
                  prefixIcon: Icons.link_rounded,
                ),
                const SizedBox(height: 48),
                AccentGradientButton(
                  text: 'Save Changes',
                  isLoading: _isLoading,
                  onPressed: _saveProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
