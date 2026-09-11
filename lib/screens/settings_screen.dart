import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/cycle_provider.dart';
import '../theme/app_theme.dart';
import 'cycle_data_screen.dart';
import 'about_screen.dart';
import 'terms_screen.dart';
import 'data_privacy_screen.dart';
import 'sign_in_screen.dart';
import 'health_diary_screen.dart'; // ← NEW IMPORT

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = 'Your Name';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('userName');
    if (savedName != null && savedName.isNotEmpty && mounted) {
      setState(() => _userName = savedName);
    }
  }

  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
  }

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: AppTextStyles.serif(size: 22, color: colors.onSurface),
              ),
              const SizedBox(height: 20),
              _profileCard(colors),

              const SizedBox(height: 20),
              _sectionHeading('HEALTH', Icons.favorite_outline),
              const SizedBox(height: 12),
              _settingsRow(context, colors, '📖', 'My Health Diary', 'View', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HealthDiaryScreen(),
                  ),
                );
              }),

              const SizedBox(height: 20),
              _sectionHeading('CYCLE SETTINGS', Icons.water_drop_outlined),
              const SizedBox(height: 12),
              _settingsRow(context, colors, '🩸', 'Cycle Data', 'Edit', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CycleDataScreen(),
                  ),
                );
              }),
              _reminderToggleRow(context, cycle, colors),
              _settingsRow(context, colors, '📊', 'Data & Privacy', 'Manage', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DataPrivacyScreen(),
                  ),
                );
              }),
              const SizedBox(height: 20),
              _sectionHeading('APPEARANCE', Icons.dark_mode_outlined),
              const SizedBox(height: 12),
              _appearanceCard(cycle, colors, isDark),

              const SizedBox(height: 20),
              _sectionHeading('ABOUT', Icons.info_outline),
              const SizedBox(height: 12),
              _settingsRow(context, colors, 'ℹ️', 'About Wellness Saheli', '', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              }),
              _settingsRow(context, colors, '📋', 'Terms & Privacy', '', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsScreen()),
                );
              }),
              _settingsRow(
                context,
                colors,
                '⭐',
                'Rate the App',
                '',
                () => _showRateDialog(context),
              ),

              const SizedBox(height: 20),
              _logoutButton(context, colors),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeading(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.sans(
            size: 12,
            weight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _appearanceCard(
    CycleProvider cycle,
    ColorScheme colors,
    bool isDark,
  ) {
    final platformBrightness = MediaQuery.of(context).platformBrightness;
    final systemModeLabel = platformBrightness == Brightness.dark
        ? 'System: Dark'
        : 'System: Light';
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: cycle.themeMode,
              onChanged: (value) {
                if (value != null) {
                  context.read<CycleProvider>().setThemeMode(value);
                }
              },
              title: Text(
                'Follow system',
                style: AppTextStyles.sans(
                  size: 14,
                  weight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              subtitle: Text(
                systemModeLabel,
                style: AppTextStyles.sans(
                  size: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          Divider(height: 1, color: colors.outline),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: cycle.themeMode,
              onChanged: (value) {
                if (value != null) {
                  context.read<CycleProvider>().setThemeMode(value);
                }
              },
              title: Text(
                'Light',
                style: AppTextStyles.sans(
                  size: 14,
                  weight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          Divider(height: 1, color: colors.outline),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: cycle.themeMode,
              onChanged: (value) {
                if (value != null) {
                  context.read<CycleProvider>().setThemeMode(value);
                }
              },
              title: Text(
                'Dark',
                style: AppTextStyles.sans(
                  size: 14,
                  weight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(ColorScheme colors) {
    return InkWell(
      onTap: () => _showEditNameDialog(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.cardBorder,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    style: AppTextStyles.sans(
                      size: 15,
                      weight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Edit Profile',
                    style: AppTextStyles.sans(
                      size: 11,
                      color: colors.onTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: _userName == 'Your Name' ? '' : _userName,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Edit Name',
          style: AppTextStyles.sans(size: 16, weight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.sans(size: 14),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: AppTextStyles.sans(
              size: 14,
              color: AppColors.textSecondary,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              final finalName = newName.isEmpty ? 'Your Name' : newName;
              setState(() => _userName = finalName);
              _saveUserName(finalName);
              Navigator.pop(dialogContext);
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsRow(
    BuildContext context,
    ColorScheme colors,
    String emoji,
    String title,
    String value,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.sans(
                  size: 14,
                  weight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ),
            if (value.isNotEmpty) ...[
              Text(
                value,
                style: AppTextStyles.sans(
                  size: 12,
                  color: colors.onTertiary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderToggleRow(
    BuildContext context,
    CycleProvider cycle,
    ColorScheme colors,
  ) {
    // NOTE: if this switch still doesn't visually turn on after tapping,
    // the bug is inside cycle_provider.dart — either `remindersEnabled`
    // isn't being updated, or `toggleReminders()` isn't calling
    // notifyListeners(). This widget itself reads/writes correctly.
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          const Text('🔔', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Reminders',
              style: AppTextStyles.sans(
                size: 14,
                weight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
          Switch(
            value: cycle.remindersEnabled,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              context.read<CycleProvider>().toggleReminders(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _logoutButton(BuildContext context, ColorScheme colors) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              'Log Out',
              style: AppTextStyles.sans(size: 16, weight: FontWeight.w600),
            ),
            content: Text(
              'Are you sure you want to log out?',
              style: AppTextStyles.sans(
                size: 13,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Close the confirmation dialog first, then navigate to
                  // Sign In and clear the entire navigation stack behind
                  // it, so the back button can't return into the app.
                  Navigator.pop(dialogContext);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignInScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: Text(
                  'Log Out',
                  style: TextStyle(color: const Color(0xFFE57373)),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          'Log Out',
          style: AppTextStyles.sans(
            size: 14,
            weight: FontWeight.w600,
            color: const Color(0xFFE57373),
          ),
        ),
      ),
    );
  }

  void _showRateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Rate the App',
          style: AppTextStyles.sans(size: 16, weight: FontWeight.w600),
        ),
        content: Text(
          'Thanks for using Wellness Saheli! App store rating will be available once the app is published.',
          style: AppTextStyles.sans(size: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
