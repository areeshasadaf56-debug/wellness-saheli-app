/// auth_session.dart
///
/// Tiny static holder for the signed-in account's user_id and session
/// token. CycleProvider sets these on signIn()/signUp()/app launch and
/// clears them on logout(). HealthProfileService and AiService read
/// from here so every request that touches personal data sends
/// `Authorization: Bearer <token>` and uses the account's user_id
/// (not the old anonymous per-device id) -- matching what the server
/// now requires (see auth_utils.require_auth on the backend).
library;

class AuthSession {
  static String? userId;
  static String? token;

  static Map<String, String> get authHeaders =>
      token == null ? {} : {'Authorization': 'Bearer $token'};

  static void clear() {
    userId = null;
    token = null;
  }
}
