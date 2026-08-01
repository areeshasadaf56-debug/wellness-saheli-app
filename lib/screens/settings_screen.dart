import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../theme/app_theme.dart';
import 'cycle_data_screen.dart';
import 'about_screen.dart';
import 'terms_screen.dart';
import 'data_privacy_screen.dart';
import 'sign_in_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: AppTextStyles.serif(size: 22)),
              const SizedBox(height: 20),
              _profileCard(context, cycle),

              const SizedBox(height: 20),
              _sectionHeading('CYCLE SETTINGS'),
              const SizedBox(height: 10),
              _settingsRow(context, '🩸', 'Cycle Data', 'Edit', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CycleDataScreen(),
                  ),
                );
              }),
              _reminderToggleRow(context, cycle),
              _settingsRow(context, '📊', 'Data & Privacy', 'Manage', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DataPrivacyScreen(),
                  ),
                );
              }),

              const SizedBox(height: 20),
              _sectionHeading('ABOUT'),
              const SizedBox(height: 10),
              _settingsRow(context, 'ℹ️', 'About Wellness Saheli', '', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              }),
              _settingsRow(context, '📋', 'Terms & Privacy', '', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsScreen()),
                );
              }),
              _settingsRow(
                context,
                '⭐',
                'Rate the App',
                '',
                () => _showRateDialog(context),
              ),

              const SizedBox(height: 20),
              _logoutButton(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeading(String text) {
    return Text(
      text,
      style: AppTextStyles.sans(
        size: 11,
        weight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _profileCard(BuildContext context, CycleProvider cycle) {
    return GestureDetector(
      onTap: () => _showEditNameDialog(context, cycle),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
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
                    cycle.userName.isNotEmpty ? cycle.userName : 'Your Name',
                    style: AppTextStyles.sans(
                      size: 15,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Edit Profile',
                    style: AppTextStyles.sans(
                      size: 11,
                      color: AppColors.textSecondary,
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

  void _showEditNameDialog(BuildContext context, CycleProvider cycle) {
    final controller = TextEditingController(text: cycle.userName);
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
              // Persisted centrally in CycleProvider so Home's "Hello, {name}"
              // greeting and this profile card always agree.
              context.read<CycleProvider>().updateUserName(
                newName.isEmpty ? 'Your Name' : newName,
              );
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
    String emoji,
    String title,
    String value,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.sans(size: 14, weight: FontWeight.w600),
              ),
            ),
            if (value.isNotEmpty) ...[
              Text(
                value,
                style: AppTextStyles.sans(
                  size: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
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

  Widget _reminderToggleRow(BuildContext context, CycleProvider cycle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Text('🔔', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Reminders',
              style: AppTextStyles.sans(size: 14, weight: FontWeight.w600),
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

  Widget _logoutButton(BuildContext context) {
    return GestureDetector(
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
                  // Close the confirm dialog first, then clear login state
                  // and clear the whole nav stack so Back can't return here.
                  Navigator.pop(dialogContext);
                  context.read<CycleProvider>().logout();
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
