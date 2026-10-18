import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import 'responsive.dart';

/// The page behind every main screen: plain paper, inside the safe area.
///
/// With [maxWidth], the content is centred and capped at that width so a
/// single-column screen doesn't stretch across a desktop window.
class AmbientBackground extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const AmbientBackground({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: maxWidth == null ? child : ContentWidth(maxWidth: maxWidth!, child: child),
      ),
    );
  }
}
