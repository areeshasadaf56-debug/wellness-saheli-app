import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'ovulation_screen.dart';
import 'protection_screen.dart';
import 'pmos_screen.dart';
import 'endo_screen.dart';
import 'learn_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    OvulationScreen(),
    ProtectionScreen(),
    PmosScreen(),
    EndoScreen(),
    LearnScreen(),
    SettingsScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem('🌙', 'Cycle'),
    _NavItem('🥚', 'Ovulation'),
    _NavItem('🛡️', 'Protection'),
    _NavItem('📋', 'PMOS'),
    _NavItem('🔭', 'Endo'),
    _NavItem('📖', 'Learn'),
    _NavItem('⚙️', 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_navItems.length, (index) {
                final isActive = index == _currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _navItems[index].emoji,
                          style: TextStyle(
                            fontSize: 18,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _navItems[index].label,
                          style: AppTextStyles.sans(
                            size: 9,
                            color: isActive
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
      ),
    );
  }
}

class _NavItem {
  final String emoji;
  final String label;
  const _NavItem(this.emoji, this.label);
}
