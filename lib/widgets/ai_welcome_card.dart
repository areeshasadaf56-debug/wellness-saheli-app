import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'gradient_card.dart';
import 'pill_button.dart';

/// AI Welcome Card
///
/// A beautiful, premium-looking AI companion introduction card that appears
/// at the top of the home dashboard. Designed to make users feel like they
/// have a personal health companion available.
class AiWelcomeCard extends StatelessWidget {
  final String userName;
  final VoidCallback onTap;
  final String? currentPhase;
  final int? currentCycleDay;
  final DateTime? lastCheckIn;
  final int? selfReportedStressLevel;
  final String? latestDiaryMood;

  const AiWelcomeCard({
    super.key,
    required this.userName,
    required this.onTap,
    this.currentPhase,
    this.currentCycleDay,
    this.lastCheckIn,
    this.selfReportedStressLevel,
    this.latestDiaryMood,
  });

  String _getGreetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getSaheliGreeting() {
    // Personalize using what we actually know about her, most specific
    // signal first -- falls back to a generic time-based line only when
    // there's nothing to go on yet.
    if (selfReportedStressLevel != null && selfReportedStressLevel! >= 4) {
      return 'Things have seemed heavy lately -- want to talk? 💛';
    }

    if (lastCheckIn != null) {
      final daysSince = DateTime.now().difference(lastCheckIn!).inDays;
      if (daysSince >= 7) {
        return 'It\'s been a while -- how have you really been? ✨';
      }
    } else {
      return 'Haven\'t met yet -- I\'d love to get to know you 🌸';
    }

    if (latestDiaryMood != null) {
      final moodWord = latestDiaryMood!
          .split(' ')
          .skip(1)
          .join(' ')
          .toLowerCase();
      if (moodWord == 'sad' ||
          moodWord == 'irritable' ||
          moodWord == 'anxious') {
        return 'Last time you mentioned feeling $moodWord -- how\'s that now?';
      }
    }

    final greeting = _getGreetingByTime();
    final time = greeting.replaceAll('Good ', '').toLowerCase();

    switch (time) {
      case 'morning':
        return 'Starting your day strong? 🌸';
      case 'afternoon':
        return 'How\'s your day been? ✨';
      case 'evening':
        return 'Time to check in? 🌙';
      default:
        return 'How are you feeling today? ✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = userName.isNotEmpty ? userName : 'there';
    final greeting = _getGreetingByTime();
    final saheliMsg = _getSaheliGreeting();

    return GestureDetector(
      onTap: onTap,
      child: GradientCard(
        borderRadius: 20,
        colors: const [AppColors.primary, AppColors.accent],
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: greeting + Saheli info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, $displayName 👋',
                        style: AppTextStyles.serif(
                          size: 18,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your personal health companion',
                        style: AppTextStyles.sans(
                          size: 12,
                          weight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                // AI icon/avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Conversation starter
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      saheliMsg,
                      style: AppTextStyles.sans(
                        size: 14,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // CTA Button
            SizedBox(
              width: double.infinity,
              child: Center(
                child: PillButton(
                  label: 'Talk to Saheli',
                  icon: Icons.favorite_rounded,
                  color: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: onTap,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Cycle phase indicator (if available)
            if (currentPhase != null && currentCycleDay != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPhaseIcon(currentPhase!),
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Day $currentCycleDay • $currentPhase',
                      style: AppTextStyles.sans(
                        size: 11,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getPhaseIcon(String phase) {
    switch (phase) {
      case 'Menstrual':
        return Icons.water_drop;
      case 'Follicular':
        return Icons.local_florist;
      case 'Ovulation':
        return Icons.wb_sunny;
      case 'Luteal':
        return Icons.nightlight_round;
      default:
        return Icons.info_outline;
    }
  }
}
