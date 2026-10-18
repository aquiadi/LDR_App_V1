import 'package:flutter/material.dart';

/// Layout breakpoints, by the width actually available to the app.
///
/// compact: phones. medium: tablets in portrait and small windows.
/// expanded: tablets in landscape and desktops.
class Breakpoints {
  Breakpoints._();

  static const double medium = 600;
  static const double expanded = 960;

  static bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).width < medium;
  static bool isExpanded(BuildContext context) => MediaQuery.sizeOf(context).width >= expanded;
}

/// Centres [child] and caps its width, so text lines and forms stay a
/// readable length on a tablet or a desktop window.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentWidth({super.key, required this.child, this.maxWidth = 640});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
