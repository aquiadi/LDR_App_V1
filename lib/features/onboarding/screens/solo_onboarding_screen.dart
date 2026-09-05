import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/custom_textfield.dart';
import 'package:go_router/go_router.dart';
import '../providers/invite_provider.dart';

class SoloOnboardingScreen extends ConsumerStatefulWidget {
  const SoloOnboardingScreen({super.key});

  @override
  ConsumerState<SoloOnboardingScreen> createState() => _SoloOnboardingScreenState();
}

class _SoloOnboardingScreenState extends ConsumerState<SoloOnboardingScreen> {
  final PageController _pageController = PageController();
  final _spaceNameController = TextEditingController();
  final _welcomeMessageController = TextEditingController();
  DateTime? _anniversaryDate;

  int _currentIndex = 0;
  bool _isCreating = false;

  @override
  void dispose() {
    _pageController.dispose();
    _spaceNameController.dispose();
    _welcomeMessageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    await ref.read(inviteControllerProvider.notifier).generateInvite(
          spaceName: _spaceNameController.text.trim().isNotEmpty
              ? _spaceNameController.text.trim()
              : null,
          anniversaryDate: _anniversaryDate,
          welcomeMessage: _welcomeMessageController.text.trim().isNotEmpty
              ? _welcomeMessageController.text.trim()
              : null,
        );

    if (!mounted) return;
    setState(() => _isCreating = false);

    // Previously this navigated unconditionally, so a failed creation landed
    // the user on an invite screen with no code and no explanation.
    final result = ref.read(inviteControllerProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't create your space: ${result.error}"),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.go('/invite');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentIndex > 0 && !_isCreating
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                onPressed: () {
                  _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
              )
            : null,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Progress Indicator
              Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentIndex ? AppColors.primary : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: [
                    _buildNameStep(),
                    _buildDateStep(),
                    _buildMessageStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name your space', style: AppTypography.h1),
        const SizedBox(height: 8),
        Text('Give your shared world a special name.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _spaceNameController,
          labelText: 'Space Name',
          hintText: 'e.g. Our Little Corner',
        ),
        const Spacer(),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildDateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('When did it start?', style: AppTypography.h1),
        const SizedBox(height: 8),
        Text('Set your anniversary date so we can celebrate milestones.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      surface: AppColors.surfaceElevated,
                      onSurface: AppColors.textPrimary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                _anniversaryDate = date;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceElevated),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _anniversaryDate != null
                      ? '${_anniversaryDate!.day}/${_anniversaryDate!.month}/${_anniversaryDate!.year}'
                      : 'Select Date',
                  style: AppTypography.bodyLarge.copyWith(
                    color: _anniversaryDate != null ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                const Icon(Icons.calendar_today_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const Spacer(),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildMessageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Leave a welcome note', style: AppTypography.h1),
        const SizedBox(height: 8),
        Text('This is the first thing they will see when they join.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _welcomeMessageController,
          labelText: 'Welcome Message',
          hintText: 'I made this for us...',
          // maxLines is not in CustomTextField by default, let me just remove it to be safe.
        ),
        const Spacer(),
        _buildNextButton(label: 'Finish & Invite'),
      ],
    );
  }

  Widget _buildNextButton({String label = 'Next'}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isCreating ? null : _nextPage,
        child: _isCreating 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.textPrimary, strokeWidth: 2))
            : Text(label, style: AppTypography.buttonText),
      ),
    );
  }
}
