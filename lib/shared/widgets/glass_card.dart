import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final Color? borderGradientColor;
  final Color? fillGradientColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24.0,
    this.blur = 12.0,
    this.borderGradientColor,
    this.fillGradientColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderGradientColor ?? Colors.white.withValues(alpha: 0.1),
              width: 1.0,
            ),
            color: fillGradientColor ?? Colors.white.withValues(alpha: 0.04),
            // Optional: Inner glow can be simulated with an inner shadow or just leaving as is
          ),
          child: child,
        ),
      ),
    );
  }
}
