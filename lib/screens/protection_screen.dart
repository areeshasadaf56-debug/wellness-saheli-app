import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProtectionScreen extends StatefulWidget {
  const ProtectionScreen({super.key});

  @override
  State<ProtectionScreen> createState() => _ProtectionScreenState();
}

class _ProtectionScreenState extends State<ProtectionScreen> {
  int _activeTab = 0;

  final List<Map<String, dynamic>> _methods = const [
    {
      'emoji': '🛡️',
      'badgeColor': AppColors.ovulationTeal,
      'name': 'Condom',
      'effectiveness': '85–98% effective',
      'detail':
          'The only method that protects against both pregnancy and STIs. Used correctly every time, effectiveness reaches 98%. Typical use is around 85% due to user error. Use a new condom every time. Check the expiry date, leave space at the tip. Use water-based lubricant only with latex condoms.',
      'tags': [
        {'label': 'STI Protection', 'color': AppColors.ovulationTeal},
        {'label': 'No hormones', 'color': AppColors.ovulationTeal},
        {'label': 'User-dependent', 'color': AppColors.periodRed},
      ],
    },
    {
      'emoji': '💊',
      'badgeColor': AppColors.periodRed,
      'name': 'Combined Pill (OCP)',
      'effectiveness': '91–99% effective',
      'detail':
          'Oral contraceptive pills combine estrogen and progestin, which prevent ovulation. Must be taken at the same time daily. Missing a pill reduces effectiveness sharply. Does not protect against STIs. Can also help regulate periods, reduce cramps, and manage acne.',
      'tags': [
        {'label': 'Highly effective', 'color': AppColors.ovulationTeal},
        {'label': 'No STI protection', 'color': AppColors.periodRed},
        {'label': 'Daily routine', 'color': AppColors.moodYellow},
      ],
    },
    {
      'emoji': '⚓',
      'badgeColor': AppColors.textSecondary,
      'name': 'IUCD',
      'effectiveness': '>99% effective',
      'detail':
          'A T-shaped device inserted into the uterus by a healthcare provider. Two types: hormonal (Mirena) that release progestin and work 3–8 years, copper (non-hormonal) that is hormone-free and provides long-term protection. Also the most effective emergency contraception if inserted within 5 days of unprotected sex.',
      'tags': [
        {'label': 'Long-term', 'color': AppColors.ovulationTeal},
        {'label': 'Most effective', 'color': AppColors.ovulationTeal},
        {'label': 'No STI protection', 'color': AppColors.periodRed},
      ],
    },
    {
      'emoji': '📍',
      'badgeColor': AppColors.periodRed,
      'name': 'Implant',
      'effectiveness': '>99% effective',
      'detail':
          'A small rod inserted under the skin of the upper arm. Releases progestin for up to 3 years. One of the most effective methods available. Requires a healthcare provider for insertion and removal. Periods may become irregular or stop. Fertility returns quickly after removal.',
      'tags': [
        {'label': 'Set and forget', 'color': AppColors.ovulationTeal},
        {'label': '3 years', 'color': AppColors.primary},
        {'label': 'No STI protection', 'color': AppColors.periodRed},
      ],
    },
    {
      'emoji': '⚡',
      'badgeColor': AppColors.moodYellow,
      'name': 'Emergency Contraception',
      'effectiveness': '75–99% effective',
      'detail':
          'Also called the "morning after pill". Works by delaying or preventing ovulation. Most effective within 72 hours of unprotected sex. Ella (ulipristal) works up to 5 days. The copper IUD is the most effective option within 5 days (>99%). It is NOT an abortion pill and does NOT terminate an established pregnancy.',
      'tags': [
        {'label': 'Within 72 hrs', 'color': AppColors.moodYellow},
        {'label': 'Not regular use', 'color': AppColors.periodRed},
        {'label': 'No STI protection', 'color': AppColors.periodRed},
      ],
    },
  ];

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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildTabs(),
            const SizedBox(height: 20),
            if (_activeTab == 0)
              ..._buildContraceptionTab()
            else
              _buildMyPlanTab(),
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

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(
          child: _tabButton('🛡️', 'Contraception', 0, AppColors.ovulationTeal),
        ),
        const SizedBox(width: 10),
        Expanded(child: _tabButton('💊', 'My Plan', 1, AppColors.periodRed)),
      ],
    );
  }

  Widget _tabButton(String emoji, String label, int index, Color activeColor) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? activeColor.withOpacity(0.6)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.sans(
                size: 13,
                weight: FontWeight.w600,
                color: isActive
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContraceptionTab() {
    return [
      _heroCard(),
      const SizedBox(height: 24),
      Text(
        'CONTRACEPTION METHODS',
        style: AppTextStyles.sans(
          size: 11,
          weight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 12),
      ..._methods.map(
        (m) => MethodCard(
          emoji: m['emoji'] as String,
          badgeColor: m['badgeColor'] as Color,
          title: m['name'] as String,
          subtitle: m['effectiveness'] as String,
          detail: m['detail'] as String,
          tags: m['tags'] as List<Map<String, dynamic>>,
        ),
      ),
    ];
  }

  Widget _buildMyPlanTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.periodRed.withOpacity(0.15),
            ),
            child: const Center(
              child: Text('💊', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No plan selected yet',
            style: AppTextStyles.sans(size: 14, weight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a method from the Contraception tab to track it here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.sans(size: 12, color: AppColors.textSecondary),
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
        border: Border.all(color: AppColors.ovulationTeal.withOpacity(0.3)),
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
              child: Text('🛡️', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 14),
          Text('Protective Sex', style: AppTextStyles.serif(size: 19)),
          const SizedBox(height: 8),
          Text(
            'Using contraception correctly is one of the most responsible health decisions you can make. No method is 100% effective — layering methods gives the best protection.',
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

// Always-expanded method card: emoji badge, title + effectiveness,
// full description, and colored tag chips at the bottom.
class MethodCard extends StatelessWidget {
  final String emoji;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final String detail;
  final List<Map<String, dynamic>> tags;

  const MethodCard({
    super.key,
    required this.emoji,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.sans(
                        size: 14,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.sans(size: 11, color: badgeColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            detail,
            style: AppTextStyles.sans(
              size: 12,
              color: AppColors.textSecondary,
            ).copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((t) {
              final color = t['color'] as Color;
              final label = t['label'] as String;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.sans(
                    size: 10,
                    weight: FontWeight.w600,
                    color: color,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
