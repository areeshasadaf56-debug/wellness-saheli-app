import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/health_profile.dart';
import '../providers/cycle_provider.dart';
import '../services/health_profile_service.dart';
import '../services/ai_service.dart';

class _ChatSession {
  final String sessionId;
  final List<ConversationEntry> entries;
  _ChatSession(this.sessionId, this.entries);

  DateTime get lastActivity => entries.last.timestamp;

  String get title {
    final firstUser = entries.firstWhere(
      (e) => e.role == 'user',
      orElse: () => entries.first,
    );
    final text = firstUser.message.trim();
    if (text.isEmpty) return 'New chat';
    return text.length > 40 ? '${text.substring(0, 40)}…' : text;
  }
}

class AiCheckinScreen extends StatefulWidget {
  final void Function(String tabName)? onNavigateToTab;

  const AiCheckinScreen({super.key, this.onNavigateToTab});

  @override
  State<AiCheckinScreen> createState() => _AiCheckinScreenState();
}

class _AiCheckinScreenState extends State<AiCheckinScreen> {
  final HealthProfileService _profileService = HealthProfileService();
  final AiService _aiService = AiService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  HealthProfile? _profile;
  final List<ConversationEntry> _messages = [];
  String _currentSessionId = '';
  bool _loading = true;
  bool _sending = false;
  bool _showCrisisBanner = false;
  bool _showMedicalEmergencyBanner = false;
  String? _pendingSuggestedTab;
  String? _pendingSuggestedReason;
  String? _errorText;

  static const _openingGreeting =
      "Hi -- I'm here to check in on how you've really been. Take your "
      "time, there's no rush. How have you been feeling lately, overall?";

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<_ChatSession> _sessionsFrom(HealthProfile p) {
    final grouped = <String, List<ConversationEntry>>{};
    for (final e in p.conversationLog) {
      final key = e.sessionId ?? 'legacy';
      grouped.putIfAbsent(key, () => []).add(e);
    }
    final sessions = grouped.entries
        .map((e) => _ChatSession(e.key, e.value))
        .toList();
    sessions.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return sessions;
  }

  Future<void> _loadInitialState() async {
    final profile = await _profileService.loadProfile();
    if (!mounted) return;

    final sessions = _sessionsFrom(profile);
    setState(() {
      _profile = profile;
      if (sessions.isNotEmpty) {
        _currentSessionId = sessions.first.sessionId;
        _messages.addAll(sessions.first.entries);
      } else {
        _startFreshSession();
      }
      _loading = false;
    });
  }

  void _startFreshSession() {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _messages.clear();
    _messages.add(
      ConversationEntry(
        timestamp: DateTime.now(),
        role: 'assistant',
        message: _openingGreeting,
        sessionId: _currentSessionId,
      ),
    );
    _pendingSuggestedTab = null;
    _pendingSuggestedReason = null;
    _showCrisisBanner = false;
    _showMedicalEmergencyBanner = false;
  }

  void _startNewChat() {
    setState(_startFreshSession);
  }

  void _openHistory() {
    final sessions = _sessionsFrom(_profile!);
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
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chats',
                        style: AppTextStyles.sans(
                          size: 16,
                          weight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _startNewChat();
                        },
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'New chat',
                              style: AppTextStyles.sans(
                                size: 13,
                                weight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: sessions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No past chats yet.',
                            style: AppTextStyles.sans(
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: sessions.length,
                          itemBuilder: (context, index) {
                            final s = sessions[index];
                            final isActive = s.sessionId == _currentSessionId;
                            return ListTile(
                              onTap: () {
                                Navigator.pop(sheetContext);
                                setState(() {
                                  _currentSessionId = s.sessionId;
                                  _messages
                                    ..clear()
                                    ..addAll(s.entries);
                                  _pendingSuggestedTab = null;
                                  _pendingSuggestedReason = null;
                                });
                              },
                              leading: Icon(
                                Icons.chat_bubble_outline,
                                size: 18,
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              title: Text(
                                s.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.sans(
                                  size: 13,
                                  weight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                _formatDate(s.lastActivity),
                                style: AppTextStyles.sans(
                                  size: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
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
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    _inputController.clear();
    setState(() {
      _sending = true;
      _errorText = null;
      _pendingSuggestedTab = null;
      _pendingSuggestedReason = null;
    });

    final historyForRequest = _profile!.privacySettings.aiMemoryEnabled
        ? List<ConversationEntry>.from(_messages)
        : <ConversationEntry>[];

    final profileContext = _buildProfileContext();

    final userEntry = ConversationEntry(
      timestamp: DateTime.now(),
      role: 'user',
      message: text,
      sessionId: _currentSessionId,
    );
    setState(() => _messages.add(userEntry));
    _scrollToBottom();

    await _profileService.appendConversationEntry(
      'user',
      text,
      sessionId: _currentSessionId,
    );

    try {
      final result = await _aiService.sendMessage(
        message: text,
        history: historyForRequest,
        profileContext: profileContext,
      );

      final assistantEntry = ConversationEntry(
        timestamp: DateTime.now(),
        role: 'assistant',
        message: result.reply,
        sessionId: _currentSessionId,
      );

      await _profileService.appendConversationEntry(
        'assistant',
        result.reply,
        sessionId: _currentSessionId,
      );

      HealthProfile? updatedProfile;
      if (result.profileUpdates != null) {
        updatedProfile = await _profileService.updateProfile(
          (p) => _applyStructuredUpdates(p, result.profileUpdates!),
        );
      }

      if (!mounted) return;
      setState(() {
        _messages.add(assistantEntry);
        if (updatedProfile != null) _profile = updatedProfile;
        _pendingSuggestedTab = result.suggestedTab;
        _pendingSuggestedReason = result.suggestedTabReason;
        if (result.crisisConcern) _showCrisisBanner = true;
        if (result.medicalEmergencyConcern) _showMedicalEmergencyBanner = true;
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _errorText = "Couldn't reach the check-in assistant. Please try again.";
      });
    }
  }

  HealthProfile _applyStructuredUpdates(
    HealthProfile current,
    Map<String, dynamic> updates,
  ) {
    var result = current;

    final lifestyleUpdate = updates['lifestyle'] as Map<String, dynamic>?;
    if (lifestyleUpdate != null && lifestyleUpdate.isNotEmpty) {
      final merged = {...result.lifestyle.toJson(), ...lifestyleUpdate};
      result = result.copyWith(lifestyle: Lifestyle.fromJson(merged));
    }

    final mentalHealthUpdate =
        updates['mental_health'] as Map<String, dynamic>?;
    final lifeContextUpdate = updates['life_context'] as Map<String, dynamic>?;
    if ((mentalHealthUpdate != null && mentalHealthUpdate.isNotEmpty) ||
        (lifeContextUpdate != null && lifeContextUpdate.isNotEmpty)) {
      final merged = {
        ...result.mentalHealth.toJson(),
        ...?mentalHealthUpdate,
        if (lifeContextUpdate?['financial_stress'] != null)
          'financial_stress': lifeContextUpdate!['financial_stress'],
        if (lifeContextUpdate?['relationship_status'] != null)
          'relationship_status': lifeContextUpdate!['relationship_status'],
        if (lifeContextUpdate?['relationship_or_marital_difficulty'] != null)
          'relationship_or_marital_difficulty':
              lifeContextUpdate!['relationship_or_marital_difficulty'],
        if (lifeContextUpdate?['family_conflict'] != null)
          'family_conflict': lifeContextUpdate!['family_conflict'],
        if (lifeContextUpdate?['support_system_notes'] != null)
          'support_system_notes': lifeContextUpdate!['support_system_notes'],
        'last_check_in': DateTime.now().toIso8601String(),
      };
      result = result.copyWith(
        mentalHealth: MentalHealthFlags.fromJson(merged),
      );
    }

    final reproUpdate =
        updates['reproductive_history'] as Map<String, dynamic>?;
    if (reproUpdate != null && reproUpdate.isNotEmpty) {
      final merged = {...result.reproductiveHistory.toJson(), ...reproUpdate};
      result = result.copyWith(
        reproductiveHistory: ReproductiveHistory.fromJson(merged),
      );
    }

    return result;
  }

  Map<String, dynamic> _buildProfileContext() {
    final p = _profile!;
    final cycle = context.read<CycleProvider>().cycleData;

    final ctx = <String, dynamic>{
      'demographics': {
        'age_yrs': p.demographics.ageYrs,
        'marital_status': p.demographics.maritalStatus,
      },
      'lifestyle': p.lifestyle.toJson(),
      'mental_health': p.mentalHealth.toJson(),
      'reproductive_history': {
        'cycle_regularity': p.reproductiveHistory.cycleRegularity,
        'current_contraception_method':
            p.reproductiveHistory.currentContraceptionMethod,
      },
      'pcos_history_count': p.pcosHistory.length,
      'latest_pcos_result': p.pcosHistory.isNotEmpty
          ? p.pcosHistory.last.prediction
          : null,
      'cycle': {
        'current_cycle_day': cycle.getCurrentCycleDay(),
        'phase': cycle.getPhase(),
        'days_until_next_period': cycle.daysUntilNextPeriod(),
      },
    };

    if (p.privacySettings.aiCanAccessDiary && p.diaryEntries.isNotEmpty) {
      final recent = p.diaryEntries.length > 5
          ? p.diaryEntries.sublist(p.diaryEntries.length - 5)
          : p.diaryEntries;
      ctx['recent_diary_entries'] = recent
          .map(
            (d) => {
              'date': d.date.toIso8601String(),
              'mood': d.mood,
              'symptom_tags': d.symptomTags,
              'text': d.text,
            },
          )
          .toList();
    }

    return ctx;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Column(
        children: [
          _topBar(),
          if (_showMedicalEmergencyBanner) _medicalEmergencyBanner(),
          if (_showCrisisBanner) _crisisBanner(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount:
                  _messages.length + (_pendingSuggestedTab != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _messageBubble(_messages[index]);
                }
                return _suggestionCard(
                  _pendingSuggestedTab!,
                  _pendingSuggestedReason,
                );
              },
            ),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _errorText!,
                style: AppTextStyles.sans(size: 12, color: AppColors.periodRed),
              ),
            ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Saheli',
              style: AppTextStyles.sans(size: 15, weight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: _openHistory,
            icon: const Icon(Icons.history_rounded),
            color: AppColors.textSecondary,
            iconSize: 20,
          ),
          IconButton(
            onPressed: _startNewChat,
            icon: const Icon(Icons.add_comment_outlined),
            color: AppColors.textSecondary,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _medicalEmergencyBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.periodRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.periodRed.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, size: 18, color: AppColors.periodRed),
              const SizedBox(width: 8),
              Text(
                'This may need urgent medical care',
                style: AppTextStyles.sans(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.periodRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'What you\'ve described could be a medical emergency. Please '
            'seek in-person medical attention now -- an emergency room or '
            'urgent care -- rather than continuing to rely on this chat.',
            style: AppTextStyles.sans(
              size: 12,
              color: AppColors.textSecondary,
            ).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _crisisBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.periodRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.periodRed.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, size: 16, color: AppColors.periodRed),
              const SizedBox(width: 8),
              Text(
                'You matter, and support is available',
                style: AppTextStyles.sans(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: AppColors.periodRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'If things feel like too much right now, please consider reaching '
            'out to a crisis helpline in your area, or to someone you trust.',
            style: AppTextStyles.sans(
              size: 12,
              color: AppColors.textSecondary,
            ).copyWith(height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Befrienders Worldwide (befrienders.org) lists crisis lines by country.',
            style: AppTextStyles.sans(
              size: 11,
              color: AppColors.periodRed,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(ConversationEntry entry) {
    final isUser = entry.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          border: isUser ? null : Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          entry.message,
          style: AppTextStyles.sans(
            size: 13.5,
            color: isUser ? Colors.white : AppColors.textPrimary,
          ).copyWith(height: 1.45),
        ),
      ),
    );
  }

  Widget _suggestionCard(String tab, String? reason) {
    final label = tab == 'pcos'
        ? 'PCOS Detection'
        : 'Contraception & Protection';
    final color = tab == 'pcos' ? AppColors.periodRed : AppColors.ovulationTeal;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.explore_outlined, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                'Worth a look: $label',
                style: AppTextStyles.sans(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          if (reason != null) ...[
            const SizedBox(height: 6),
            Text(
              reason,
              style: AppTextStyles.sans(
                size: 12,
                color: AppColors.textSecondary,
              ).copyWith(height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(tab);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Open the $label tab to check this out'),
                    ),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.6)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Take me there',
                style: AppTextStyles.sans(size: 12.5, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: null,
              icon: const Icon(Icons.add),
              color: AppColors.textSecondary,
              iconSize: 20,
            ),
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Message Saheli…',
                  hintStyle: AppTextStyles.sans(
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            IconButton(
              onPressed: null,
              icon: const Icon(Icons.mic_none_rounded),
              color: AppColors.textSecondary,
              iconSize: 20,
            ),
            _sending
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    color: Colors.white,
                    iconSize: 18,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
