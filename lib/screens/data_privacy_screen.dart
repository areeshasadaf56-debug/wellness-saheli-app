import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backHeader(context, 'Data & Privacy'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.ovulationTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.ovulationTeal.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your cycle data lives only on this device. Nothing is uploaded to a server.',
                        style: AppTextStyles.sans(
                          size: 12,
                          color: AppColors.textPrimary,
                        ).copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _section(
                'What We Store',
                'Period start and end dates, cycle length settings, symptoms you log, moods you log, and reminder preferences. All of this is saved locally in the app\'s own storage on your phone — the same way notes or offline apps keep data on your device.',
              ),
              _section(
                'What We Don\'t Do',
                'We don\'t run analytics that identify you personally, we don\'t sell or share your health data with advertisers, and we don\'t require an account or login, so there\'s no profile of you sitting on a server anywhere.',
              ),
              _section(
                'Why We Ask for This Data',
                'Cycle dates, symptoms, and mood logs are used only to power the predictions and insights inside the app — like your current cycle day, upcoming period estimate, and fertility window. None of it leaves your device to do this.',
              ),
              _section(
                'Your Control',
                'You can edit or delete your cycle data at any time from Settings → Cycle Data. Uninstalling the app removes all locally stored data along with it, since nothing is backed up to an external server by default.',
              ),
              _section(
                'If You Share Your Device',
                'Because data is stored locally, anyone with access to your unlocked phone could open the app and see your logs. If that\'s a concern, consider using your phone\'s built-in app lock or biometric lock features for extra privacy.',
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backHeader(BuildContext context, String title) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(
              Icons.arrow_back,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppTextStyles.serif(size: 20)),
      ],
    );
  }

  Widget _section(String heading, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: AppTextStyles.sans(
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTextStyles.sans(
              size: 13,
              color: AppColors.textSecondary,
            ).copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
