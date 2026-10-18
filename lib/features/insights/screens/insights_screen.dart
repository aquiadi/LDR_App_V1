import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/ambient_background.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive.dart';
import '../providers/insights_provider.dart';
import '../../auth/providers/partner_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  static int _asInt(dynamic value) =>
      value is num ? value.round() : int.tryParse('$value') ?? 0;

  static List<double> _asDoubles(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e is num ? e.toDouble() : double.tryParse('$e') ?? 0.0)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(weeklyInsightsProvider);
    final partnerName =
        ref.watch(partnerStreamProvider).valueOrNull?.displayName ?? 'your partner';
    String heroSubtitle(int pct) => pct >= 75
        ? 'Your energy and $partnerName\'s have been closely in step this week.'
        : pct >= 50
            ? 'Mostly in step with $partnerName, with a few different days.'
            : 'You and $partnerName are having quite different weeks. Worth a call?';

    return AmbientBackground(
      maxWidth: 704,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: insightsAsync.when(
          data: (data) {
            if (data.isEmpty) return const Center(child: Text('Not enough data yet.'));
            return ListView(
              padding: EdgeInsets.fromLTRB(Breakpoints.isCompact(context) ? 20 : 32, 24, Breakpoints.isCompact(context) ? 20 : 32, 32),
              children: [
                Text('This week', style: AppTypography.headlineLg),
                const SizedBox(height: 4),
                Text(
                  'Worked out from the last seven days of check-ins.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                // Values arrive as decoded JSON, so numbers are `num` and
                // lists are `List<dynamic>`. Casting straight to List<double>
                // threw as soon as the edge function was actually deployed —
                // only the hard-coded fallback ever satisfied that cast.
                _buildSyncHero(_asInt(data['syncPercentage']), subtitle: heroSubtitle(_asInt(data['syncPercentage']))),
                const SizedBox(height: 32),
                _buildTrendChart(_asDoubles(data['trendData'])),
                const SizedBox(height: 32),
                _buildCatalystCard(data['catalystPrompt']?.toString() ?? ''),
                const SizedBox(height: 32),
                _buildTipsList(data['tips'] is List ? data['tips'] as List<dynamic> : const []),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildSyncHero(int percentage, {required String subtitle}) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer,
              ),
            ),
            Column(
              children: [
                Text('$percentage%', style: AppTypography.display.copyWith(fontSize: 64, color: AppColors.onPrimaryContainer)),
                Text('in sync', style: AppTypography.bodyMd.copyWith(color: AppColors.onPrimaryContainer)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(subtitle, style: AppTypography.bodyMd, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildTrendChart(List<double> trendData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Energy this week', style: AppTypography.cardTitle),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            height: 150,
            child: CustomPaint(
              size: const Size(double.infinity, 150),
              painter: _TrendChartPainter(data: trendData),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCatalystCard(String prompt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Something to try', style: AppTypography.cardTitle),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prompt, style: AppTypography.headlineMd.copyWith(fontSize: 24, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsList(List<dynamic> tips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Small things that help', style: AppTypography.cardTitle),
        const SizedBox(height: 16),
        ...tips.map((tip) {
          final iconData = tip['icon'] == 'chat_bubble_outline' 
              ? Icons.chat_bubble_outline_rounded 
              : Icons.favorite_border_rounded;
              
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tip['title'] as String, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(tip['desc'] as String, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> data;

  _TrendChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const maxVal = 100.0; // Assume percentages
    // A one-point series would make dx infinite and the path degenerate.
    if (data.length < 2) return;
    final dx = size.width / (data.length - 1);

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = size.height - (data[i] / maxVal) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Create smooth cubic bezier curve
        final prevX = (i - 1) * dx;
        final prevY = size.height - (data[i - 1] / maxVal) * size.height;
        final cpX1 = prevX + dx / 2;
        final cpY1 = prevY;
        final cpX2 = x - dx / 2;
        final cpY2 = y;
        path.cubicTo(cpX1, cpY1, cpX2, cpY2, x, y);
      }
    }

    // Paint line
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    // Paint fill area
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.18),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Paint dots
    final dotPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
      
    final dotBorderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = size.height - (data[i] / maxVal) * size.height;
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      canvas.drawCircle(Offset(x, y), 5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      !listEquals(oldDelegate.data, data);
}
