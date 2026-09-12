import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/ai_response.dart';
import '../models/health_profile.dart';
import 'auth_session.dart';

class AiService {
  Future<AiResponse> sendMessage({
    required String message,
    required List<ConversationEntry> history,
    Map<String, dynamic>? profileContext,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/chat');
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            // /chat now requires a signed-in session (see chat_api.py).
            ...AuthSession.authHeaders,
          },
          body: jsonEncode({
            'message': message,
            'history': history
                .map((e) => {'role': e.role, 'message': e.message})
                .toList(),
            // ignore: use_null_aware_elements
            if (profileContext != null) 'profile_context': profileContext,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
        'Chat request failed (${response.statusCode}): ${response.body}',
      );
    }

    return AiResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
