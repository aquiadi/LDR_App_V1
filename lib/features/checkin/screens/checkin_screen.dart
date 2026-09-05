import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/mood_catalog.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/ambient_background.dart';
import '../../../shared/widgets/accent_gradient_button.dart';
import '../providers/checkin_provider.dart';
import '../../../services/checkin_service.dart' show kMinMoodScore, kMaxMoodScore;
import '../../auth/providers/partner_provider.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  int _energyScore = 5;
  bool _submitting = false;
  String _selectedEmoji = 'sentiment_very_satisfied'; // We use icons now, mapped to string
  String _moodLabel = 'Joyful';
  final _thoughtsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existingCheckin = ref.read(todayCheckinProvider).valueOrNull;
      if (existingCheckin != null) {
        setState(() {
          _energyScore = existingCheckin.energyScore;
          _selectedEmoji = existingCheckin.moodEmoji;
          _moodLabel = existingCheckin.moodLabel;
          _thoughtsController.text = existingCheckin.journalNote ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _thoughtsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    // Affection and stress are not yet surfaced in the UI; the midpoint is a
    // deliberate neutral default rather than a placeholder to remove later.
    await ref.read(todayCheckinProvider.notifier).submitCheckin(
          moodEmoji: _selectedEmoji,
          moodLabel: _moodLabel,
          affectionScore: 5,
          stressScore: 5,
          energyScore: _energyScore,
          journalNote: _thoughtsController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    // Only leave the screen when the write actually succeeded. Popping
    // unconditionally made a failed check-in look like a successful one.
    final result = ref.read(todayCheckinProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't save your check-in: ${result.error}"),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.pop();
  }

  String _getEnergyLabel() {
    if (_energyScore <= 2) return 'Resting';
    if (_energyScore <= 4) return 'Mellow';
    if (_energyScore <= 6) return 'Neutral';
    if (_energyScore <= 8) return 'Dynamic';
    return 'Electric';
  }

  @override
  Widget build(BuildContext context) {
    final checkinState = ref.watch(todayCheckinProvider);

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                _buildCeremonialGreeting(),
                const SizedBox(height: 48),
                _buildMainInteractiveContent(checkinState),
                const SizedBox(height: 48),
                Text(
                  '"Distance is just a test to see how far love can travel."',
                  style: AppTypography.bodySm.copyWith(fontStyle: FontStyle.italic, color: AppColors.outline.withValues(alpha: 0.6)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const SizedBox.shrink(),
      leadingWidth: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHigh,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
            ),
            child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text('LDR Sync', style: AppTypography.headlineMd.copyWith(color: AppColors.primary)),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.primary),
            onPressed: () => context.pop(),
          ),
        ),
      ],
    );
  }

  Widget _buildCeremonialGreeting() {
    final partnerName = ref.watch(partnerStreamProvider).valueOrNull?.displayName;
    return Column(
      children: [
        Text('Daily Check-In', style: AppTypography.headlineLgMobile),
        const SizedBox(height: 8),
        Text(
          partnerName == null
              ? 'Share how you\'re feeling today.'
              : 'Tell $partnerName how you\'re feeling today.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }

  Widget _buildMainInteractiveContent(AsyncValue checkinState) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEnergySlider(),
              const SizedBox(width: 24),
              Expanded(child: _buildMoodSelector()),
            ],
          ),
          const SizedBox(height: 32),
          _buildThoughtsField(),
          const SizedBox(height: 32),
          AccentGradientButton(
            text: 'Share Vibe',
            icon: Icons.send_rounded,
            isLoading: checkinState.isLoading || _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildEnergySlider() {
    return Column(
      children: [
        Text('ENERGY', style: AppTypography.labelMd.copyWith(color: AppColors.outline, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              // Bounds mirror the database CHECK constraint. A 0 here used to
              // be rejected by Postgres, losing the whole check-in.
              value: _energyScore.toDouble(),
              min: kMinMoodScore.toDouble(),
              max: kMaxMoodScore.toDouble(),
              divisions: kMaxMoodScore - kMinMoodScore,
              activeColor: AppColors.primary,
              inactiveColor: Colors.white.withValues(alpha: 0.1),
              onChanged: (val) {
                setState(() {
                  _energyScore = val.toInt();
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _getEnergyLabel(),
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('I\'M FEELING...', style: AppTypography.labelMd.copyWith(color: AppColors.outline, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.2,
          children: kMoodOptions.map((mood) {
            final isSelected = _selectedEmoji == mood.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedEmoji = mood.id;
                  _moodLabel = mood.label;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(mood.icon, color: AppColors.primary, size: 28),
                    const SizedBox(height: 8),
                    Text(mood.label, style: AppTypography.labelMd),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildThoughtsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WHAT\'S ON YOUR MIND?', style: AppTypography.labelMd.copyWith(color: AppColors.outline, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: _thoughtsController,
          maxLines: 4,
          style: AppTypography.bodyLg,
          decoration: InputDecoration(
            hintText: 'Share a little more...',
            hintStyle: AppTypography.bodyLg.copyWith(color: AppColors.outlineVariant),
            filled: false,
            border: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.outlineVariant)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.outlineVariant)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
