/// ai_checkin_service.dart
///
/// Talks to the /chat backend endpoint. Kept separate from
/// HealthProfileService because this one is stateless per call (it doesn't
/// persist anything itself) -- the screen using it decides what to do
/// with the reply, including writing to the profile.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/health_profile.dart';

class ChatTurnResult {
  final String reply;
  final Map<String, dynamic>? profileUpdates;
  final String? suggestedTab; // 'pcos' | 'protection' | null
  final String? suggestedTabReason;
  final bool crisisConcern;

  ChatTurnResult({
    required this.reply,
    this.profileUpdates,
    this.suggestedTab,
    this.suggestedTabReason,
    this.crisisConcern = false,
  });

  factory ChatTurnResult.fromJson(Map<String, dynamic> json) {
    return ChatTurnResult(
      reply: json['reply'] as String? ?? '',
      profileUpdates: json['profile_updates'] as Map<String, dynamic>?,
      suggestedTab: json['suggested_tab'] as String?,
      suggestedTabReason: json['suggested_tab_reason'] as String?,
      crisisConcern: json['crisis_concern'] as bool? ?? false,
    );
  }
}

class AiCheckinService {
  /// Sends [message] plus the recent [history] to the backend and returns
  /// the assistant's structured reply. Throws on network/server error --
  /// the caller (the chat screen) is responsible for showing a friendly
  /// "couldn't connect" state rather than this service inventing one,
  /// since a chat UI needs to show the failure inline with the message
  /// that failed to send.
  Future<ChatTurnResult> sendMessage({
    required String message,
    required List<ConversationEntry> history,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/chat');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': message,
            // Only send role + message -- the backend doesn't need
            // timestamps, and trimming keeps the payload small as the
            // conversation log grows over many sessions.
            'history': history
                .map((e) => {'role': e.role, 'message': e.message})
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
        'Chat request failed (${response.statusCode}): ${response.body}',
      );
    }

    return ChatTurnResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
