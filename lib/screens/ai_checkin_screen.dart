/// ai_checkin_screen.dart
///
/// The "personal check-in" chat screen. Loads past conversation from the
/// user's HealthProfile (so returning users pick up where they left off),
/// sends new messages to the backend /chat endpoint, and:
///   - appends both sides of the conversation to the diary
///   - applies any structured profile updates the AI extracted
///   - shows a "check this out" card when the AI suggests a tab
///   - shows a crisis-resources banner if the AI flags a concern
///
/// This screen does NOT perform navigation itself -- pass an
/// [onNavigateToTab] callback (e.g. from your bottom-nav / IndexedStack
/// shell) so this widget stays decoupled from your specific navigation
/// setup. If you don't pass one, the suggestion card still shows but
/// tapping it just tells the user which tab to open manually.
library;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/health_profile.dart';
import '../services/health_profile_service.dart';
import '../services/ai_checkin_service.dart';

class AiCheckinScreen extends StatefulWidget {
  /// Called with 'pcos' or 'protection' when the user taps a tab
  /// suggestion card. Wire this to whatever switches your main
  /// IndexedStack/bottom-nav tab.
  final void Function(String tabName)? onNavigateToTab;

  const AiCheckinScreen({super.key, this.onNavigateToTab});

  @override
  State<AiCheckinScreen> createState() => _AiCheckinScreenState();
}

class _AiCheckinScreenState extends State<AiCheckinScreen> {
  final HealthProfileService _profileService = HealthProfileService();
  final AiCheckinService _chatService = AiCheckinService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // This field may be used in future to hold the loaded health profile.
  // Keep it to avoid refactor churn; suppress unused-field analyzer warning.
  // ignore: unused_field
  HealthProfile? _profile;
  final List<ConversationEntry> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _showCrisisBanner = false;
  String? _pendingSuggestedTab;
  String? _pendingSuggestedReason;
  String? _errorText;

  static const _openingGreeting =
      "Hi — I'm here to check in on how you've been doing. There's no "
      "right or wrong way to answer, and we can go at whatever pace "
      "feels comfortable. To start, how have the last couple of weeks "
      "been for you overall?";

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

  Future<void> _loadInitialState() async {
    final profile = await _profileService.loadProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      // Every time this screen opens, start a fresh conversation rather
      // than replaying every past check-in ever had. Past turns are
      // still permanently saved to the diary via
      // appendConversationEntry() on each send below -- they're just not
      // redisplayed here. Replaying full history on every open would also
      // keep growing the context sent to the AI on every single message.
      _messages.add(
        ConversationEntry(
          timestamp: DateTime.now(),
          role: 'assistant',
          message: _openingGreeting,
        ),
      );
      _loading = false;
    });
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

    // History sent to the backend is everything before this new message.
    final historyForRequest = List<ConversationEntry>.from(_messages);

    final userEntry = ConversationEntry(
      timestamp: DateTime.now(),
      role: 'user',
      message: text,
    );
    setState(() => _messages.add(userEntry));
    _scrollToBottom();

    // Persist the user's turn to the diary immediately -- even if the AI
    // call below fails, their message shouldn't be lost.
    await _profileService.appendConversationEntry('user', text);

    try {
      final result = await _chatService.sendMessage(
        message: text,
        history: historyForRequest,
      );

      final assistantEntry = ConversationEntry(
        timestamp: DateTime.now(),
        role: 'assistant',
        message: result.reply,
      );

      await _profileService.appendConversationEntry('assistant', result.reply);

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
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _errorText =
            "Couldn't reach the check-in assistant just now. Please try again in a moment.";
      });
    }
  }

  /// Shallow-merges the AI's partial update maps (snake_case, matching
  /// health_profile.dart's toJson shape) into the corresponding nested
  /// object of [current]. A shallow merge is correct here because every
  /// field inside lifestyle/mental_health/reproductive_history is a flat
  /// scalar -- there's no nested structure within them that a shallow
  /// merge would clobber.
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
    if (mentalHealthUpdate != null && mentalHealthUpdate.isNotEmpty) {
      final merged = {
        ...result.mentalHealth.toJson(),
        ...mentalHealthUpdate,
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
    // FIX: this screen is pushed directly via Navigator.push from
    // HomeScreen, with no Scaffold/Material ancestor above it anywhere in
    // the tree. The chat input below is a TextField, and TextField (like
    // most Material widgets) requires a Material ancestor to render --
    // without this Scaffold, Flutter throws "No Material widget found"
    // the moment this screen builds. Every other pushed screen in this
    // app (HealthDiaryScreen, etc.) wraps itself in its own Scaffold for
    // exactly this reason; this screen was just missing it.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(context),
                  if (_showCrisisBanner) _crisisBanner(),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount:
                          _messages.length +
                          (_pendingSuggestedTab != null ? 1 : 0),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Text(
                        _errorText!,
                        style: AppTextStyles.sans(
                          size: 12,
                          color: AppColors.periodRed,
                        ),
                      ),
                    ),
                  _inputBar(),
                ],
              ),
      ),
    );
  }

  /// Matches the back-button + title pattern used by HealthDiaryScreen,
  /// since this screen (like that one) is pushed via Navigator.push and
  /// has no bottom-nav/AppBar of its own to provide a way back.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Check ',
                  style: AppTextStyles.serif(
                    size: 20,
                    weight: FontWeight.w600,
                    color: AppColors.accent,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
                TextSpan(
                  text: 'In',
                  style: AppTextStyles.serif(
                    size: 20,
                    weight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
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
        color: AppColors.periodRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.periodRed.withOpacity(0.35)),
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
            'out to a crisis helpline in your area, or to someone you trust. '
            "You don't have to go through this alone.",
            style: AppTextStyles.sans(
              size: 12,
              color: AppColors.textSecondary,
            ).copyWith(height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            // TODO: replace with a locale-specific national helpline once
            // you know your primary user base's country — a wrong number
            // here is worse than a generic international directory.
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
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
                side: BorderSide(color: color.withOpacity(0.6)),
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type your reply…',
                hintStyle: AppTextStyles.sans(
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _sending
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    shape: const CircleBorder(),
                  ),
                ),
        ],
      ),
    );
  }
}
