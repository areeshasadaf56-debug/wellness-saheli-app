import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'ovulation_screen.dart';
import 'protection_screen.dart';
import 'pcos_screen.dart';
import 'endo_screen.dart';
import 'learn_screen.dart';
import 'settings_screen.dart';

// The app's main shell after sign-in: a bottom nav bar switching between
// the 7 primary tabs. Each tab's screen is kept alive in an IndexedStack
// so switching tabs doesn't rebuild/reset their state.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;

  final List<Widget> _tabs = const [
    HomeScreen(),
    OvulationScreen(),
    ProtectionScreen(),
    PcosScreen(),
    EndoScreen(),
    LearnScreen(),
    SettingsScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.nightlight_round, label: 'Cycle'),
    _NavItem(icon: Icons.egg_outlined, label: 'Ovulation'),
    _NavItem(icon: Icons.shield_outlined, label: 'Protection'),
    _NavItem(icon: Icons.bubble_chart_outlined, label: 'PCOS'),
    _NavItem(icon: Icons.local_florist_outlined, label: 'Endo'),
    _NavItem(icon: Icons.menu_book_outlined, label: 'Learn'),
    _NavItem(icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(index: _tabIndex, children: _tabs),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final active = _tabIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _tabIndex = i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: active
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: AppTextStyles.sans(
                          size: 10,
                          weight: active ? FontWeight.w600 : FontWeight.normal,
                          color: active
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
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
  const _NavItem({required this.icon, required this.label});
}
