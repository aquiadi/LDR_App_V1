import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/mood_catalog.dart';
import '../../../shared/widgets/responsive.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/checkin_provider.dart';
import '../../../services/checkin_service.dart' show kMinMoodScore, kMaxMoodScore;
import '../../auth/providers/partner_provider.dart';
import '../../dashboard/providers/prompt_provider.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  int _energyScore = 5;
  bool _submitting = false;
  String _selectedEmoji = 'sentiment_very_satisfied'; // a mood id from kMoodOptions
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
    final partnerName = ref.watch(partnerStreamProvider).valueOrNull?.displayName;
    final prompt = ref.watch(dailyPromptProvider);
    final busy = checkinState.isLoading || _submitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Check in'),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: ContentWidth(
                  maxWidth: 560,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How was today, really?', style: AppTypography.headlineLg),
                      const SizedBox(height: 8),
                      Text(
                        partnerName == null
                            ? 'Your partner sees this the moment you send it.'
                            : '$partnerName sees this the moment you send it.',
                        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 32),
                      const _SectionLabel('Mood'),
                      const SizedBox(height: 12),
                      _buildMoodSelector(),
                      const SizedBox(height: 32),
                      _buildEnergySlider(),
                      const SizedBox(height: 32),
                      const _SectionLabel('In a line or two'),
                      const SizedBox(height: 4),
                      Text(
                        "Today's question: $prompt",
                        style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                      ),
                      const SizedBox(height: 12),
                      _buildThoughtsField(),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.outlineVariant)),
              ),
              child: ContentWidth(
                maxWidth: 560,
                child: PrimaryButton(
                  text: partnerName == null ? 'Send check-in' : 'Send to $partnerName',
                  icon: Icons.arrow_upward_rounded,
                  isLoading: busy,
                  onPressed: _submit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel('Energy'),
            const Spacer(),
            Text(
              '$_energyScore · ${_getEnergyLabel()}',
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Slider(
          // Bounds mirror the database CHECK constraint. A 0 here used to
          // be rejected by Postgres, losing the whole check-in.
          value: _energyScore.toDouble(),
          min: kMinMoodScore.toDouble(),
          max: kMaxMoodScore.toDouble(),
          divisions: kMaxMoodScore - kMinMoodScore,
          label: '$_energyScore',
          onChanged: (val) => setState(() => _energyScore = val.toInt()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Running on empty', style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
              Text('Buzzing', style: AppTypography.bodySm.copyWith(color: AppColors.outline)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 420 ? 3 : 2;
        const spacing = 10.0;
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: kMoodOptions.map((mood) {
            final isSelected = _selectedEmoji == mood.id;
            return SizedBox(
              width: width,
              child: Semantics(
                button: true,
                selected: isSelected,
                child: Material(
                  color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() {
                      _selectedEmoji = mood.id;
                      _moodLabel = mood.label;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Icon(mood.icon, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            mood.label,
                            style: AppTypography.bodyMd.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildThoughtsField() {
    return TextField(
      controller: _thoughtsController,
      minLines: 3,
      maxLines: 6,
      style: AppTypography.bodyLg,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(hintText: 'Share a little more...'),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTypography.cardTitle.copyWith(fontSize: 15));
}
