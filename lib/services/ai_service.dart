import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/ai_response.dart';
import '../models/health_profile.dart';

class AiService {
  /// [authToken] is required -- the backend's /chat endpoint requires a
  /// valid `Authorization: Bearer <token>` header (see chat_api.py) and
  /// will reject the request otherwise. Pass `context.read<CycleProvider>()
  /// .authToken` from the caller.
  Future<AiResponse> sendMessage({
    required String message,
    required List<ConversationEntry> history,
    required String? authToken,
    Map<String, dynamic>? profileContext,
  }) async {
    if (authToken == null || authToken.isEmpty) {
      throw Exception('not_signed_in');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/chat');
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
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

    if (response.statusCode == 401) {
      throw Exception('not_signed_in');
    }

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
