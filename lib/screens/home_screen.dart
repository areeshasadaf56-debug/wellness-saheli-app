import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/cycle_provider.dart';
import '../widgets/month_calendar.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  static const _bannerDismissedKey = 'ai_checkin_banner_dismissed';

  bool _showAiBanner = false;
  bool _bannerStateLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerState();
  }

  Future<void> _loadBannerState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_bannerDismissedKey) ?? false;
    if (!mounted) return;
    setState(() {
      _showAiBanner = !dismissed;
      _bannerStateLoaded = true;
    });
  }

  Future<void> _dismissAiBanner() async {
    setState(() => _showAiBanner = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bannerDismissedKey, true);
  }

  /// Switches the shell to the Check-in tab (see home_shell.dart), rather
  /// than pushing a separate screen instance -- this way there's only
  /// ever one AiCheckinScreen, kept alive in the shell's IndexedStack.
  void _openAiCheckin() {
    widget.onNavigateToTab?.call('checkin');
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

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(cycle),
            const SizedBox(height: 12),
            _buildHeader(context),
            if (_bannerStateLoaded && _showAiBanner) ...[
              const SizedBox(height: 18),
              _buildAiCheckinBanner(context),
            ],
            const SizedBox(height: 28),
            _buildCycleDial(cycle),
            const SizedBox(height: 24),
            _buildStatusCards(cycle),
            const SizedBox(height: 24),
            _sectionLabel('THIS WEEK'),
            const SizedBox(height: 10),
            const MonthCalendar(),
            const SizedBox(height: 24),
            _sectionLabel('LOG TODAY'),
            const SizedBox(height: 10),
            _buildLogButtons(context),
            const SizedBox(height: 24),
            _sectionLabel("TODAY'S INSIGHT"),
            const SizedBox(height: 10),
            _buildInsightCard(cycle),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(CycleProvider cycle) {
    final name = cycle.userName.isNotEmpty ? cycle.userName : 'there';
    return Text(
      'Hello, $name 👋',
      style: AppTextStyles.sans(
        size: 13,
        weight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.sans(
        size: 11,
        weight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                color: AppColors.textSecondary,
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

  /// Optional, dismissible entry point into the AI check-in -- per the
  /// chosen onboarding approach, this is NOT a forced flow. It sits on
  /// Home so it's easy to find, but a tap of the X hides it permanently
  /// (persisted via SharedPreferences) for users who'd rather explore
  /// the app on their own. Tapping the banner itself switches to the
  /// Check-in tab rather than opening a separate screen.
  Widget _buildAiCheckinBanner(BuildContext context) {
    return GestureDetector(
      onTap: _openAiCheckin,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.12),
              AppColors.accent.withOpacity(0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Want a quick check-in?',
                    style: AppTextStyles.sans(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "I'll ask a few questions and point you to what's "
                    "most useful, based on how you're doing.",
                    style: AppTextStyles.sans(
                      size: 11.5,
                      color: AppColors.textSecondary,
                    ).copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _dismissAiBanner,
              child: Icon(
                Icons.close,
                size: 18,
                color: AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleDial(CycleProvider cycle) {
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
                border: Border.all(color: AppColors.cardBorder, width: 3),
              ),
            ),
            Positioned(
              top: -3,
              child: Container(
                width: 28,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${cycle.currentCycleDay}',
                  style: AppTextStyles.serif(
                    size: 42,
                    color: AppColors.periodRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CYCLE DAY',
                  style: AppTextStyles.sans(
                    size: 10,
                    weight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.periodRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cycle.currentPhase,
                    style: AppTextStyles.sans(
                      size: 11,
                      color: AppColors.periodRed,
                      weight: FontWeight.w600,
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

    return Row(
      children: [
        Expanded(
          child: _statusCard(
            label: 'NEXT PERIOD',
            value: '${cycle.daysUntilNextPeriod}d',
            subLabel: nextPeriodLabel,
            accentColor: AppColors.periodRed,
            useAccent: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statusCard(
            label: 'FERTILITY',
            value: fertilityLabel,
            subLabel: ovulationSubLabel,
            accentColor: AppColors.textPrimary,
            useAccent: false,
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
    required bool useAccent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: useAccent
              ? accentColor.withOpacity(0.35)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.sans(
              size: 10,
              weight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.serif(
              size: 22,
              color: useAccent ? accentColor : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: AppTextStyles.sans(size: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLogButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _logButton(
            context,
            Icons.water_drop,
            'Period Flow',
            AppColors.periodRed,
            () => _showFlowInfoDialog(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _logButton(
            context,
            Icons.nightlight_round,
            'Mood',
            AppColors.moodYellow,
            () => _showMoodPicker(context, DateTime.now()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _logButton(
            context,
            Icons.assignment_outlined,
            'Symptoms',
            AppColors.symptomOrange,
            () => _showSymptomPicker(context, DateTime.now()),
          ),
        ),
      ],
    );
  }

  Widget _logButton(
    BuildContext context,
    IconData icon,
    String label,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, size: 18, color: iconColor)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.sans(
                size: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFlowInfoDialog(BuildContext context) {
    final options = [
      {'label': 'None', 'desc': 'No flow today'},
      {'label': 'Spotting', 'desc': 'Very light, occasional drops'},
      {'label': 'Light', 'desc': 'Light flow, pad/tampon change every 4-6 hrs'},
      {'label': 'Medium', 'desc': 'Regular flow, change every 3-4 hrs'},
      {'label': 'Heavy', 'desc': 'Heavy flow, change every 1-2 hrs'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
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
                                  color: AppColors.textSecondary,
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
      backgroundColor: AppColors.surface,
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
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cardBorder),
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
      backgroundColor: AppColors.surface,
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
                                    ? AppColors.primary.withOpacity(0.2)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: Text(
                                s,
                                style: AppTextStyles.sans(
                                  size: 13,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
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

  Widget _buildInsightCard(CycleProvider cycle) {
    final phase = cycle.currentPhase;
    final phaseInfo = _phaseDetails(phase);
    final iconData = _phaseIconData(phase);
    final IconData phaseIcon = iconData['icon'] as IconData;
    final Color phaseColor = iconData['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(0.18),
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
                  style: AppTextStyles.sans(size: 14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  phaseInfo,
                  style: AppTextStyles.sans(
                    size: 12,
                    color: AppColors.textSecondary,
                  ).copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _phaseDetails(String phase) {
    switch (phase) {
      case 'Menstrual':
        return 'Your uterine lining is shedding, which is why energy tends to run low right now. Rest when you can and don\'t feel guilty about slowing down. Iron-rich foods like spinach, lentils, and red meat help replenish what\'s lost through bleeding, and staying hydrated eases bloating. A heating pad or warm bath on your lower abdomen relaxes the uterine muscle and can noticeably cut cramping. Light movement like walking or gentle stretching often helps more than staying still, even though it\'s tempting to just curl up.';
      case 'Follicular':
        return 'Estrogen is climbing steadily, and most people feel their energy, mood, and focus lifting day by day. This is usually the best window for starting new projects, tackling harder workouts, or scheduling things that need sharp thinking, since the brain tends to feel clearer here. Your body is also more receptive to strength training right now, so it\'s a good time to push a little in the gym. Skin often looks better too as estrogen supports collagen production.';
      case 'Ovulation':
        return 'This is your most fertile window, typically lasting about 24 hours around the release of an egg, though sperm can survive several days beforehand. Estrogen peaks and testosterone rises slightly, which is why confidence, sociability, and libido often feel highest here. Some people notice mild one-sided pelvic twinges (ovulation pain), a slight temperature rise, or clearer, stretchier cervical mucus. If you\'re tracking for conception or avoidance, this is the highest-priority window to pay attention to.';
      case 'Luteal':
        return 'Progesterone rises after ovulation and then drops sharply if pregnancy doesn\'t occur, which is what drives PMS symptoms like irritability, bloating, breast tenderness, and food cravings in the days before your period. Energy typically declines through this phase, especially in the last week. Cutting back on caffeine, alcohol, and sugar can meaningfully soften mood swings, and prioritizing sleep helps your body handle the hormonal drop. Magnesium-rich foods like dark chocolate, nuts, and leafy greens are commonly reported to ease cramping and irritability.';
      default:
        return 'Track your cycle regularly to get personalized insights about each phase.';
    }
  }
}
