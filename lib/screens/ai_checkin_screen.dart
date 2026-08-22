import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/health_profile_service.dart';
import '../widgets/wellness_check_in_dialog.dart';

class _Concern {
  final String id;
  final String label;
  const _Concern(this.id, this.label);
}

/// Concerns that, when selected, point toward the PCOS tab.
const List<_Concern> _pcosConcerns = [
  _Concern('irregular_periods', 'Irregular or missing periods'),
  _Concern('excess_hair_acne', 'Excess hair growth or acne'),
  _Concern('weight_changes', 'Unexplained weight changes'),
];

/// Concerns that point toward the Protection tab.
const List<_Concern> _protectionConcerns = [
  _Concern('need_contraception', 'Thinking about contraception options'),
  _Concern('unsure_eligibility', 'Not sure what\'s medically safe for me'),
];

/// Concerns that point toward a wellness check-in rather than either tab.
const List<_Concern> _moodConcerns = [
  _Concern('mood_stress', 'Feeling stressed or low lately'),
];

const _Concern _noneConcern = _Concern(
  'none',
  'Nothing in particular, just checking in',
);

enum _Suggestion { pcos, protection, mood, none }

/// A short, tappable check-in that asks what's on someone's mind and
/// points them to the most relevant part of the app -- the PCOS tab,
/// the Protection tab, or a quick wellness log. This lives as its own
/// tab in the bottom nav (see home_shell.dart) so it's always reachable,
/// and the Home screen's dismissible banner also lands here.
class AiCheckinScreen extends StatefulWidget {
  /// Called with 'pcos' or 'protection' when the person taps the
  /// suggestion's "Take me there" button. Wired from HomeShell so it can
  /// switch the selected bottom-nav tab.
  final void Function(String tabName)? onNavigateToTab;

  const AiCheckinScreen({super.key, this.onNavigateToTab});

  @override
  State<AiCheckinScreen> createState() => _AiCheckinScreenState();
}

class _AiCheckinScreenState extends State<AiCheckinScreen> {
  final Set<String> _selected = {};
  bool _showResult = false;

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

  void _toggle(String id) {
    setState(() {
      if (id == 'none') {
        // "None of these" is exclusive -- picking it clears everything else.
        _selected.clear();
        _selected.add('none');
      } else {
        _selected.remove('none');
        if (_selected.contains(id)) {
          _selected.remove(id);
        } else {
          _selected.add(id);
        }
      }
    });
  }

  _Suggestion _computeSuggestion() {
    final pcosCount = _pcosConcerns
        .where((c) => _selected.contains(c.id))
        .length;
    final protectionCount = _protectionConcerns
        .where((c) => _selected.contains(c.id))
        .length;
    final moodCount = _moodConcerns
        .where((c) => _selected.contains(c.id))
        .length;

    if (pcosCount == 0 && protectionCount == 0 && moodCount == 0) {
      return _Suggestion.none;
    }
    // Priority: PCOS and Protection are actionable health-guidance tools,
    // so they outrank a mood-only signal when both are present.
    if (pcosCount >= protectionCount &&
        pcosCount >= moodCount &&
        pcosCount > 0) {
      return _Suggestion.pcos;
    }
    if (protectionCount >= moodCount && protectionCount > 0) {
      return _Suggestion.protection;
    }
    return _Suggestion.mood;
  }

  Future<void> _promptWellnessCheckIn() async {
    final profile = await HealthProfileService().loadProfile();
    if (!mounted) return;
    await showWellnessCheckInDialog(context, current: profile, onSaved: () {});
  }

  void _reset() {
    setState(() {
      _selected.clear();
      _showResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (!_showResult)
              ..._buildQuestionView()
            else
              ..._buildResultView(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
        Text(
          _formattedDate(),
          style: AppTextStyles.sans(size: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  List<Widget> _buildQuestionView() {
    return [
      _heroCard(),
      const SizedBox(height: 24),
      Text(
        'WHAT\'S ON YOUR MIND?',
        style: AppTextStyles.sans(
          size: 11,
          weight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Select anything that applies -- I\'ll point you to what\'s most useful.',
        style: AppTextStyles.sans(size: 12, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ..._pcosConcerns.map(_concernChip),
          ..._protectionConcerns.map(_concernChip),
          ..._moodConcerns.map(_concernChip),
          _concernChip(_noneConcern),
        ],
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _selected.isEmpty
              ? null
              : () => setState(() => _showResult = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'See what\'s useful for me',
            style: AppTextStyles.sans(
              size: 14,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _concernChip(_Concern c) {
    final selected = _selected.contains(c.id);
    return GestureDetector(
      onTap: () => _toggle(c.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          c.label,
          style: AppTextStyles.sans(
            size: 12.5,
            weight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResultView() {
    final suggestion = _computeSuggestion();
    final showMoodPrompt = _selected.any(
      (id) => _moodConcerns.any((c) => c.id == id),
    );

    return [
      _resultCard(suggestion),
      if (showMoodPrompt) ...[const SizedBox(height: 14), _moodPromptCard()],
      const SizedBox(height: 20),
      GestureDetector(
        onTap: _reset,
        child: Row(
          children: [
            Icon(Icons.refresh, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Start over',
              style: AppTextStyles.sans(
                size: 13,
                weight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _resultCard(_Suggestion suggestion) {
    switch (suggestion) {
      case _Suggestion.pcos:
        return _suggestionCard(
          emoji: '🧪',
          color: AppColors.ovulationTeal,
          title: 'The PCOS tab looks relevant',
          body:
              'What you selected -- irregular periods, hair or skin changes, or weight changes -- overlaps with common PCOS symptoms. The PCOS tab has an information guide and a screening tool that gives an estimate based on your details.',
          buttonLabel: 'Take me to PCOS',
          onTap: () => widget.onNavigateToTab?.call('pcos'),
        );
      case _Suggestion.protection:
        return _suggestionCard(
          emoji: '🛡️',
          color: AppColors.primary,
          title: 'The Protection tab looks relevant',
          body:
              'You mentioned thinking about contraception or wanting to know what\'s medically safe for you. The Protection tab has an eligibility tool that checks your conditions against medical guidance, plus a full method comparison.',
          buttonLabel: 'Take me to Protection',
          onTap: () => widget.onNavigateToTab?.call('protection'),
        );
      case _Suggestion.mood:
        return _suggestionCard(
          emoji: '💛',
          color: AppColors.moodYellow,
          title: 'Sounds like today\'s been a lot',
          body:
              'Nothing you selected points to a specific screening tool right now -- but it might help to log how you\'re feeling. It\'s private, just for you, and takes a few seconds.',
          buttonLabel: 'Log how I\'m feeling',
          onTap: _promptWellnessCheckIn,
        );
      case _Suggestion.none:
        return _suggestionCard(
          emoji: '✨',
          color: AppColors.accent,
          title: 'Good to hear',
          body:
              'Nothing specific stood out, so there\'s no particular tab to point you to right now. Feel free to explore the Learn tab, or come back here anytime something changes.',
          buttonLabel: null,
          onTap: null,
        );
    }
  }

  Widget _suggestionCard({
    required String emoji,
    required Color color,
    required String title,
    required String body,
    required String? buttonLabel,
    required VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.sans(size: 15, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: AppTextStyles.sans(
              size: 12.5,
              color: AppColors.textSecondary,
            ).copyWith(height: 1.5),
          ),
          if (buttonLabel != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: AppTextStyles.sans(
                    size: 13.5,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _moodPromptCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.moodYellow.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'You also mentioned feeling stressed or low -- want to log that too?',
              style: AppTextStyles.sans(
                size: 12.5,
                color: AppColors.textSecondary,
              ).copyWith(height: 1.4),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _promptWellnessCheckIn,
            child: Text(
              'Log it',
              style: AppTextStyles.sans(
                size: 12.5,
                weight: FontWeight.w700,
                color: AppColors.moodYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 14),
          Text('Quick Check-in', style: AppTextStyles.serif(size: 19)),
          const SizedBox(height: 8),
          Text(
            'A few taps to point you toward whatever\'s most useful right now -- no forms, no pressure.',
            textAlign: TextAlign.center,
            style: AppTextStyles.sans(
              size: 12,
              color: AppColors.textSecondary,
            ).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
