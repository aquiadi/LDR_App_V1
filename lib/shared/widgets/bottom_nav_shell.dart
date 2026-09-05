import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/navigation/app_router.dart';

class BottomNavShell extends StatelessWidget {
  final Widget child;

  const BottomNavShell({super.key, required this.child});

  static const List<String> _tabs = [
    AppRoutes.dashboard,
    AppRoutes.history,
    AppRoutes.insights,
    AppRoutes.settings,
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((path) => location.startsWith(path));
    return index < 0 ? 0 : index;
  }

  void _onItemTapped(int index, BuildContext context) {
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      extendBody: true, // Crucial for glassmorphism over content
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.0,
            ),
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: AppColors.surfaceContainer.withValues(alpha: 0.6),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        icon: Icons.favorite_border_rounded,
                        activeIcon: Icons.favorite_rounded,
                        label: 'Home',
                        isActive: currentIndex == 0,
                        onTap: () => _onItemTapped(0, context),
                      ),
                      _buildNavItem(
                        icon: Icons.calendar_today_rounded,
                        activeIcon: Icons.calendar_today_rounded,
                        label: 'Journey',
                        isActive: currentIndex == 1,
                        onTap: () => _onItemTapped(1, context),
                      ),
                      _buildNavItem(
                        icon: Icons.auto_awesome_outlined,
                        activeIcon: Icons.auto_awesome_rounded,
                        label: 'Insights',
                        isActive: currentIndex == 2,
                        onTap: () => _onItemTapped(2, context),
                      ),
                      _buildNavItem(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Profile',
                        isActive: currentIndex == 3,
                        onTap: () => _onItemTapped(3, context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryContainer.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppColors.primaryContainer.withValues(alpha: 0.2),
              blurRadius: 16,
              spreadRadius: 0,
            )
          ] : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.outlineVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: isActive ? AppColors.primary : AppColors.outlineVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
