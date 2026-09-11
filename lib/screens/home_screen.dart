import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/cycle_provider.dart';
import '../models/health_profile.dart';
import '../services/health_profile_service.dart';
import '../widgets/month_calendar.dart';
import '../widgets/ai_welcome_card.dart';
import '../widgets/ai_suggestion_card.dart';
import 'health_diary_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Called with a tab name ('checkin', 'pcos', 'protection', etc.) when
  /// something on this screen should switch the shell's selected bottom
  /// -nav tab. Wired from HomeShell:
  ///   HomeScreen(onNavigateToTab: (tab) => _navigateToTab(tab))
  final void Function(String tabName)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  HealthProfile? _profile;
  bool _isFabExpanded = false;
  late final AnimationController _dialRotationController;

  @override
  void initState() {
    super.initState();
    _dialRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadProfile();
  }

  @override
  void dispose() {
    _dialRotationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await HealthProfileService().loadProfile();
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  String _formattedDate() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  /// Navigate to AI Check-in via the shell's tab navigation
  void _openAiCheckin() {
    widget.onNavigateToTab?.call('checkin');
  }

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    final colors = Theme.of(context).colorScheme;
    final nextPeriod = cycle.daysUntilNextPeriod;
    final fertileIn = _daysUntilOvulation(cycle);

    return Scaffold(
      backgroundColor: colors.surface,
      floatingActionButton: _buildQuickLogFab(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and utility icons
              _buildHeader(context),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusChip(
                    icon: Icons.calendar_today_outlined,
                    label: '$nextPeriod d to next period',
                    color: AppColors.periodRed,
                  ),
                  _statusChip(
                    icon: Icons.wb_sunny_outlined,
                    label: cycle.currentPhase == 'Ovulation'
                        ? 'Fertility window now'
                        : 'Fertility window in $fertileIn d',
                    color: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ===== PRIMARY FEATURE: AI Welcome Card =====
              AiWelcomeCard(
                userName: cycle.userName,
                onTap: _openAiCheckin,
                currentPhase: cycle.currentPhase,
                currentCycleDay: cycle.currentCycleDay,
                lastCheckIn: _profile?.mentalHealth.lastCheckIn,
                selfReportedStressLevel:
                    _profile?.mentalHealth.selfReportedStressLevel,
                latestDiaryMood:
                    _profile != null && _profile!.diaryEntries.isNotEmpty
                    ? _profile!.diaryEntries.last.mood
                    : null,
              ),
              const SizedBox(height: 24),

              // ===== CONTEXTUAL SUGGESTIONS =====
              _buildContextualSuggestions(cycle),
              const SizedBox(height: 28),

              // Cycle dial - moved down (secondary feature now)
              _buildCycleDial(cycle),
              const SizedBox(height: 24),

              // Status cards
              _buildStatusCards(cycle),
              const SizedBox(height: 24),

              // Today's mood + recent symptoms
              _buildTodaySnapshot(cycle),
              const SizedBox(height: 24),

              // Symptom/mood trends from the last 30 days
              _buildTrendsCard(cycle),
              const SizedBox(height: 24),

              // Calendar
              _sectionLabel('THIS WEEK', Icons.date_range_outlined),
              const SizedBox(height: 12),
              const MonthCalendar(),
              const SizedBox(height: 24),

              // Quick logging
              _sectionLabel('QUICK LOGGING', Icons.bolt_outlined),
              const SizedBox(height: 8),
              Text(
                'Use the + button to log flow, mood, or symptoms quickly.',
                style: AppTextStyles.sans(
                  size: 12,
                  color: colors.onTertiary,
                ).copyWith(height: 1.8),
              ),
              const SizedBox(height: 24),

              // Insight
              _sectionLabel("TODAY'S INSIGHT", Icons.auto_awesome_outlined),
              const SizedBox(height: 12),
              _buildInsightCard(cycle),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Wellness ',
                style: AppTextStyles.serif(
                  size: 22,
                  weight: FontWeight.w600,
                  color: AppColors.accent,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
              TextSpan(
                text: 'Saheli',
                style: AppTextStyles.serif(
                  size: 22,
                  weight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Text(
              _formattedDate(),
              style: AppTextStyles.sans(
                size: 11,
                color: colors.onTertiary,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HealthDiaryScreen()),
                );
              },
              child: Icon(
                Icons.menu_book_outlined,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Contextual suggestions based on cycle phase or user data
  /// For now: show relevant suggestion cards
  Widget _buildContextualSuggestions(CycleProvider cycle) {
    // Example: Show different suggestions based on cycle phase
    final phase = cycle.currentPhase;
    String suggestionTitle = '';
    String suggestionDesc = '';
    IconData suggestionIcon = Icons.lightbulb_outline;
    Color suggestionColor = AppColors.primary;

    if (phase == 'Menstrual') {
      suggestionTitle = 'Self-Care During Period';
      suggestionDesc = 'Tips for managing discomfort and boosting energy';
      suggestionIcon = Icons.favorite_border;
      suggestionColor = AppColors.periodRed;
    } else if (phase == 'Ovulation') {
      suggestionTitle = 'Fertility Window Guide';
      suggestionDesc = 'Understanding ovulation and your most fertile days';
      suggestionIcon = Icons.wb_sunny;
      suggestionColor = AppColors.accent;
    } else if (phase == 'Luteal') {
      suggestionTitle = 'Managing Luteal Phase';
      suggestionDesc = 'Nutrition and exercise for this phase';
      suggestionIcon = Icons.nightlife_outlined;
      suggestionColor = AppColors.primary;
    } else {
      suggestionTitle = 'Explore Your Cycle';
      suggestionDesc = 'Learn more about your follicular phase';
      suggestionIcon = Icons.local_florist_outlined;
      suggestionColor = AppColors.primary;
    }

    return AiSuggestionCard(
      title: suggestionTitle,
      description: suggestionDesc,
      actionText: 'Learn More',
      icon: suggestionIcon,
      accentColor: suggestionColor,
      prominent: false,
      onTap: () {
        // Navigate to Learn tab or show more details
        widget.onNavigateToTab?.call('learn');
      },
    );
  }

  Widget _buildTodaySnapshot(CycleProvider cycle) {
    final colors = Theme.of(context).colorScheme;
    final today = cycle.getLogFor(DateTime.now());
    final hasMood = today.mood != null;
    final hasSymptoms = today.symptoms.isNotEmpty;

    if (!hasMood && !hasSymptoms) return const SizedBox.shrink();

    return _AnimatedPressable(
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          if (hasMood) ...[
            Text(
              today.mood!.split(' ').first,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              today.mood!.split(' ').skip(1).join(' '),
              style: AppTextStyles.sans(
                size: 12,
                weight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
          if (hasMood && hasSymptoms) ...[
            const SizedBox(width: 12),
            Container(width: 1, height: 16, color: AppColors.cardBorder),
            const SizedBox(width: 12),
          ],
          if (hasSymptoms)
            Expanded(
              child: Text(
                today.symptoms.join(', '),
              style: AppTextStyles.sans(
                  size: 12,
                  color: colors.onTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildTrendsCard(CycleProvider cycle) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final logs = cycle.dailyLogs;

    final symptomCounts = <String, int>{};
    final moodCounts = <String, int>{};
    int loggedDays = 0;

    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final log = logs[key];
      if (log == null) continue;
      if (log.symptoms.isNotEmpty || log.mood != null) loggedDays++;
      for (final s in log.symptoms) {
        symptomCounts[s] = (symptomCounts[s] ?? 0) + 1;
      }
      if (log.mood != null) {
        moodCounts[log.mood!] = (moodCounts[log.mood!] ?? 0) + 1;
      }
    }

    if (loggedDays < 3) return const SizedBox.shrink();

    final topSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMood = moodCounts.entries.isEmpty
        ? null
        : (moodCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first;

    return _AnimatedPressable(
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LAST 30 DAYS',
            style: AppTextStyles.sans(
              size: 10,
              weight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          if (topMood != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'You most often felt ${topMood.key.split(' ').skip(1).join(' ').toLowerCase()} '
                '(${topMood.value} of $loggedDays logged days).',
                style: AppTextStyles.sans(
                  size: 12.5,
                  color: colors.onSurface,
                ).copyWith(height: 1.8),
              ),
            ),
          if (topSymptoms.isNotEmpty)
            Text(
              'Most reported: ${topSymptoms.take(3).map((e) => '${e.key} (${e.value}x)').join(', ')}.',
              style: AppTextStyles.sans(
                size: 12.5,
                color: colors.onSurface,
              ).copyWith(height: 1.8),
            ),
          const SizedBox(height: 8),
          Text(
            'This is an observation based on your logs, not a diagnosis. If a '
            'pattern is affecting your daily life, consider mentioning it to a '
            'healthcare professional.',
            style: AppTextStyles.sans(
              size: 10.5,
              color: colors.onTertiary,
            ).copyWith(fontStyle: FontStyle.italic, height: 1.8),
          ),
        ],
      ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
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

  Widget _buildCycleDial(CycleProvider cycle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.outline, width: 3),
              ),
            ),
            AnimatedBuilder(
              animation: _dialRotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _dialRotationController.value * 6.28318530718,
                  child: child,
                );
              },
              child: SizedBox(
                width: 200,
                height: 200,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: -3),
                    width: 28,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  child: Text(
                    '${cycle.currentCycleDay}',
                    key: ValueKey(cycle.currentCycleDay),
                    style: AppTextStyles.serif(
                      size: 42,
                      color: AppColors.periodRed,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CYCLE DAY',
                  style: AppTextStyles.sans(
                    size: 10,
                    weight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.periodRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    child: Text(
                      cycle.currentPhase,
                      key: ValueKey(cycle.currentPhase),
                      style: AppTextStyles.sans(
                        size: 12,
                        color: AppColors.periodRed,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCards(CycleProvider cycle) {
    final nextPeriodDate = DateTime.now().add(
      Duration(days: cycle.daysUntilNextPeriod),
    );
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final nextPeriodLabel =
        '${months[nextPeriodDate.month - 1]} ${nextPeriodDate.day}';

    final isOvulation = cycle.currentPhase == 'Ovulation';
    final fertilityLabel = isOvulation ? 'High' : 'Low';
    final ovulationSubLabel = isOvulation
        ? 'Fertile window'
        : 'Ovulation in ${_daysUntilOvulation(cycle)}d';
    final phaseColor = _phaseAccent(cycle.currentPhase);

    return Row(
      children: [
        Expanded(
          child: _statusCard(
            label: 'NEXT PERIOD',
            value: '${cycle.daysUntilNextPeriod}d',
            subLabel: nextPeriodLabel,
            accentColor: AppColors.periodRed,
            gradientBase: AppColors.periodRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statusCard(
            label: 'FERTILITY',
            value: fertilityLabel,
            subLabel: ovulationSubLabel,
            accentColor: phaseColor,
            gradientBase: phaseColor,
          ),
        ),
      ],
    );
  }

  int _daysUntilOvulation(CycleProvider cycle) {
    final ovulationDay = (cycle.cycleLength / 2).floor();
    final diff = ovulationDay - cycle.currentCycleDay;
    return diff > 0 ? diff : cycle.cycleLength + diff;
  }

  Widget _statusCard({
    required String label,
    required String value,
    required String subLabel,
    required Color accentColor,
    required Color gradientBase,
  }) {
    final colors = Theme.of(context).colorScheme;
    return _AnimatedPressable(
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientBase.withValues(alpha: 0.16),
            colors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.sans(
              size: 10,
              weight: FontWeight.w600,
              color: colors.onTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.serif(
              size: 22,
            color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
          style: AppTextStyles.sans(size: 11, color: colors.onTertiary),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildQuickLogFab(BuildContext context) {
    final actions = [
      (
        label: 'Log Flow',
        icon: Icons.water_drop_outlined,
        color: AppColors.periodRed,
        onTap: () => _showFlowInfoDialog(context),
      ),
      (
        label: 'Log Mood',
        icon: Icons.mood_outlined,
        color: AppColors.moodYellow,
        onTap: () => _showMoodPicker(context, DateTime.now()),
      ),
      (
        label: 'Log Symptoms',
        icon: Icons.assignment_outlined,
        color: AppColors.symptomOrange,
        onTap: () => _showSymptomPicker(context, DateTime.now()),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...List.generate(actions.length, (index) {
          final action = actions[index];
          return AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            offset: _isFabExpanded ? Offset.zero : const Offset(0, 0.2),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isFabExpanded ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_isFabExpanded,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FloatingActionButton.extended(
                    heroTag: 'quick_log_$index',
                    onPressed: () {
                      setState(() => _isFabExpanded = false);
                      action.onTap();
                    },
                    icon: Icon(action.icon, color: Colors.white),
                    backgroundColor: action.color,
                    label: Text(action.label),
                  ),
                ),
              ),
            ),
          );
        }),
        FloatingActionButton(
          heroTag: 'quick_log_toggle',
          onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded),
          child: AnimatedRotation(
            turns: _isFabExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _statusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.sans(
              size: 12,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showFlowInfoDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final options = [
      {'label': 'None', 'desc': 'No flow today'},
      {'label': 'Spotting', 'desc': 'Very light, occasional drops'},
      {'label': 'Light', 'desc': 'Light flow, pad/tampon change every 4-6 hrs'},
      {'label': 'Medium', 'desc': 'Regular flow, change every 3-4 hrs'},
      {'label': 'Heavy', 'desc': 'Heavy flow, change every 1-2 hrs'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Flow",
                    style: AppTextStyles.sans(
                      size: 16,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'How heavy is your flow today?',
                    style: AppTextStyles.sans(
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...options.map((opt) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          context.read<CycleProvider>().logFlowIntensity(
                            DateTime.now(),
                            opt['label']!,
                          );
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Flow logged: ${opt['label']}'),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt['label']!,
                                style: AppTextStyles.sans(
                                  size: 14,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                opt['desc']!,
                                style: AppTextStyles.sans(
                                  size: 11,
                                  color: colors.onTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMoodPicker(BuildContext context, DateTime date) {
    final colors = Theme.of(context).colorScheme;
    final moods = [
      '😊 Happy',
      '😐 Neutral',
      '😢 Sad',
      '😠 Irritable',
      '😴 Tired',
      '😰 Anxious',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How are you feeling?',
                    style: AppTextStyles.sans(
                      size: 16,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: moods.map((m) {
                      return GestureDetector(
                        onTap: () {
                          context.read<CycleProvider>().logMood(date, m);
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Mood logged: $m')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors.outline),
                          ),
                          child: Text(m, style: AppTextStyles.sans(size: 13)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSymptomPicker(BuildContext context, DateTime date) {
    final colors = Theme.of(context).colorScheme;
    final allSymptoms = [
      'Cramps',
      'Headache',
      'Bloating',
      'Fatigue',
      'Nausea',
      'Back Pain',
      'Breast Tenderness',
      'Acne',
    ];
    final existing = context.read<CycleProvider>().getLogFor(date).symptoms;
    final selected = List<String>.from(existing);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log Symptoms',
                        style: AppTextStyles.sans(
                          size: 16,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allSymptoms.map((s) {
                          final isSelected = selected.contains(s);
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  selected.remove(s);
                                } else {
                                  selected.add(s);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : colors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                     : colors.outline,
                                ),
                              ),
                              child: Text(
                                s,
                                style: AppTextStyles.sans(
                                  size: 13,
                                  color: isSelected
                                      ? AppColors.primary
                                     : colors.onSurface,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            context.read<CycleProvider>().logSymptoms(
                              date,
                              selected,
                            );
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Symptoms saved')),
                            );
                          },
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<String, dynamic> _phaseIconData(String phase) {
    switch (phase) {
      case 'Menstrual':
        return {'icon': Icons.water_drop, 'color': AppColors.periodRed};
      case 'Follicular':
        return {'icon': Icons.local_florist, 'color': AppColors.primary};
      case 'Ovulation':
        return {'icon': Icons.wb_sunny, 'color': AppColors.accent};
      case 'Luteal':
        return {'icon': Icons.nightlight_round, 'color': AppColors.primary};
      default:
        return {'icon': Icons.info_outline, 'color': AppColors.textSecondary};
    }
  }

  Color _phaseAccent(String phase) {
    switch (phase) {
      case 'Menstrual':
        return AppColors.periodRed;
      case 'Ovulation':
        return AppColors.accent;
      case 'Luteal':
        return AppColors.symptomOrange;
      case 'Follicular':
      default:
        return AppColors.primary;
    }
  }

  Widget _buildInsightCard(CycleProvider cycle) {
    final colors = Theme.of(context).colorScheme;
    final phase = cycle.currentPhase;
    final phaseInfo = _phaseDetails(phase);
    final iconData = _phaseIconData(phase);
    final IconData phaseIcon = iconData['icon'] as IconData;
    final Color phaseColor = iconData['color'] as Color;

    return _AnimatedPressable(
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            phaseColor.withValues(alpha: 0.14),
            colors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: phaseColor.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: phaseColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Icon(phaseIcon, size: 18, color: phaseColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$phase Phase',
                  style: AppTextStyles.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  phaseInfo,
                  style: AppTextStyles.sans(
                    size: 12,
                    color: colors.onTertiary,
                  ).copyWith(height: 1.8),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _phaseDetails(String phase) {
    switch (phase) {
      case 'Menstrual':
        return 'Your uterine lining is shedding, which is why energy tends to run low right now. Rest when you can and don\'t feel guilty about slowing down. Iron-rich foods like spinach, lentils[...]';
      case 'Follicular':
        return 'Estrogen is climbing steadily, and most people feel their energy, mood, and focus lifting day by day. This is usually the best window for starting new projects, tackling harder wo[...]';
      case 'Ovulation':
        return 'This is your most fertile window, typically lasting about 24 hours around the release of an egg, though sperm can survive several days beforehand. Estrogen peaks and testosterone [...]';
      case 'Luteal':
        return 'Progesterone rises after ovulation and then drops sharply if pregnancy doesn\'t occur, which is what drives PMS symptoms like irritability, bloating, breast tenderness, and food c[...]';
      default:
        return 'Track your cycle regularly to get personalized insights about each phase.';
    }
  }
}

class _AnimatedPressable extends StatefulWidget {
  final Widget child;
  const _AnimatedPressable({required this.child});

  @override
  State<_AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<_AnimatedPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
