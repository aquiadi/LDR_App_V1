import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/navigation/app_router.dart';
import 'responsive.dart';

/// The frame around the four main tabs.
///
/// Phones get a bottom bar. From tablet-landscape width up, the same tabs move
/// into a sidebar, which is where people expect navigation on a big screen
/// and keeps the content column from stretching edge to edge.
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _tabs = [
    _Tab(AppRoutes.dashboard, 'Today', Icons.wb_twilight_outlined,
        Icons.wb_twilight_rounded),
    _Tab(AppRoutes.history, 'Journey', Icons.timeline_outlined,
        Icons.timeline_rounded),
    _Tab(AppRoutes.insights, 'Insights', Icons.insights_outlined,
        Icons.insights_rounded),
    _Tab(AppRoutes.settings, 'Profile', Icons.person_outline_rounded,
        Icons.person_rounded),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((t) => location.startsWith(t.path));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final current = _selectedIndex(context);
    void go(int i) => context.go(_tabs[i].path);

    if (Breakpoints.isExpanded(context)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            _Sidebar(tabs: _tabs, current: current, onSelect: go),
            const VerticalDivider(width: 1),
            // The routes inside carry a BlockSemantics, which hides whatever
            // was painted before it in the same semantics container. That
            // was the sidebar, so screen readers couldn't reach the tabs.
            // A container of its own keeps the block inside the content.
            Expanded(child: Semantics(container: true, child: child)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _BottomItem(
                        tab: _tabs[i],
                        active: i == current,
                        onTap: () => go(i)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _Tab(this.path, this.label, this.icon, this.activeIcon);
}

class _BottomItem extends StatelessWidget {
  final _Tab tab;
  final bool active;
  final VoidCallback onTap;

  const _BottomItem(
      {required this.tab, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.outline;
    return Semantics(
      container: true,
      button: true,
      selected: active,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(active ? tab.activeIcon : tab.icon,
                  color: color, size: 22),
            ),
            const SizedBox(height: 4),
            ExcludeSemantics(
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMd.copyWith(
                  color: active ? AppColors.onSurface : AppColors.outline,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<_Tab> tabs;
  final int current;
  final ValueChanged<int> onSelect;

  const _Sidebar(
      {required this.tabs, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Wordmark(),
              ),
              const SizedBox(height: 36),
              for (var i = 0; i < tabs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _SidebarItem(
                      tab: tabs[i],
                      active: i == current,
                      onTap: () => onSelect(i)),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'One check-in a day, wherever you both are.',
                  style:
                      AppTypography.bodySm.copyWith(color: AppColors.outline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _Tab tab;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem(
      {required this.tab, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: active,
      label: tab.label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: active ? AppColors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  active ? tab.activeIcon : tab.icon,
                  size: 22,
                  color:
                      active ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  tab.label,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active
                        ? AppColors.onPrimaryContainer
                        : AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "LDR Sync" in the display face, with the two-dot mark: one dot for each
/// of you.
class Wordmark extends StatelessWidget {
  final double size;

  const Wordmark({super.key, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: AppColors.primary, size: size * 0.36),
        SizedBox(width: size * 0.12),
        _Dot(color: AppColors.secondary, size: size * 0.36),
        SizedBox(width: size * 0.35),
        Flexible(
          child: Text(
            'LDR Sync',
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: AppTypography.headlineMd.copyWith(fontSize: size, height: 1),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
