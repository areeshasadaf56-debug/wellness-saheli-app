import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/cycle_provider.dart';
import 'home_screen.dart';
import 'ovulation_screen.dart';
import 'protection_screen.dart';
import 'pcos_screen.dart';
import 'endo_screen.dart';
import 'learn_screen.dart';
import 'settings_screen.dart';
import 'ai_checkin_screen.dart';

// The app's main shell after sign-in: a bottom nav bar switching between
// the 8 primary tabs (now includes AI Check-in). Each tab's screen is kept
// alive in an IndexedStack so switching tabs doesn't rebuild/reset their state.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;

  /// Navigate to a specific tab by name or index
  void _navigateToTab(String tabName) {
    final tabMap = {
      'cycle': 0,
      'ovulation': 1,
      'protection': 2,
      'pcos': 3,
      'endo': 4,
      'learn': 5,
      'settings': 6,
      'checkin': 7,
    };

    final newIndex = tabMap[tabName] ?? 0;
    setState(() => _tabIndex = newIndex);
  }

  final List<_NavItem> _navItems = [
    const _NavItem(
      icon: Icons.nightlight_round,
      label: 'Cycle',
      shortLabel: 'Cycle',
      badgeCount: 1,
    ),
    const _NavItem(
      icon: Icons.egg_outlined,
      label: 'Ovulation',
      shortLabel: 'Ovu',
    ),
    const _NavItem(
      icon: Icons.shield_outlined,
      label: 'Protection',
      shortLabel: 'Prot',
    ),
    const _NavItem(
      icon: Icons.bubble_chart_outlined,
      label: 'PCOS',
      shortLabel: 'PCOS',
    ),
    const _NavItem(
      icon: Icons.local_florist_outlined,
      label: 'Endo',
      shortLabel: 'Endo',
    ),
    const _NavItem(
      icon: Icons.menu_book_outlined,
      label: 'Learn',
      shortLabel: 'Learn',
    ),
    const _NavItem(
      icon: Icons.settings_outlined,
      label: 'Settings',
      shortLabel: 'Set',
    ),
    const _NavItem(
      icon: Icons.favorite_rounded,
      label: 'Check-in',
      shortLabel: 'Chat',
      badgeCount: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    final colors = Theme.of(context).colorScheme;

    // Build tabs here in build() so _navigateToTab is available
    final tabs = [
      HomeScreen(onNavigateToTab: _navigateToTab),
      const OvulationScreen(),
      const ProtectionScreen(),
      const PcosScreen(),
      const EndoScreen(),
      const LearnScreen(),
      const SettingsScreen(),
      AiCheckinScreen(onNavigateToTab: _navigateToTab),
    ];
    final needsLogBadge =
        cycle.getLogFor(DateTime.now()).mood == null &&
        cycle.getLogFor(DateTime.now()).symptoms.isEmpty;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: KeyedSubtree(key: ValueKey(_tabIndex), child: tabs[_tabIndex]),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outline)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SafeArea(
          top: false,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final active = _tabIndex == i;
              final badgeCount = i == 0 && needsLogBadge ? 1 : item.badgeCount;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _tabIndex = i),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: active
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            if (badgeCount > 0)
                              Positioned(
                                right: -6,
                                top: -6,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.periodRed,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$badgeCount',
                                    style: AppTextStyles.sans(
                                      size: 9,
                                      weight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.shortLabel,
                          style: AppTextStyles.sans(
                            size: 9,
                            weight: active ? FontWeight.w600 : FontWeight.w500,
                            color: active
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String shortLabel;
  final int badgeCount;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.shortLabel,
    this.badgeCount = 0,
  });
}
