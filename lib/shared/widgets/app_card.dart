import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// A sheet of paper: warm white, a hairline edge and a soft shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final Gradient? gradient;
  final bool raised;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.color,
    this.gradient,
    this.raised = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surfaceContainer) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: gradient == null ? 1 : 0)),
        boxShadow: raised ? AppColors.cardShadow : null,
      ),
      child: child,
    );
  }
}
