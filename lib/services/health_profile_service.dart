/// health_profile_service.dart
///
/// Loads, caches, and saves the user's HealthProfile. This is the ONE
/// place every screen should go through to read or update profile data
/// -- don't call the backend directly from individual screens, so we
/// have a single place to add offline support, retry logic, etc. later.
///
/// Requires two packages in pubspec.yaml:
///   shared_preferences: ^2.2.0
///   http: ^1.1.0
/// (You likely already have `http` from pcos_api_service.dart /
/// eligibility_api_service.dart.)
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/health_profile.dart';

class HealthProfileService {
  static const _deviceIdKey = 'health_profile_device_id';
  static const _localProfileKey = 'health_profile_cache';

  String? _cachedUserId;
  HealthProfile? _cachedProfile;

  /// Returns the anonymous device id, generating and persisting one on
  /// first ever call. This id is what ties a user's data together
  /// across app sessions without requiring a login system -- if you
  /// add real accounts later, swap this for the logged-in user's id
  /// and everything else in this file keeps working unchanged.
  Future<String> getDeviceId() async {
    if (_cachedUserId != null) return _cachedUserId!;

    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdKey);
    if (id == null) {
      id = _generateId();
      await prefs.setString(_deviceIdKey, id);
    }
    _cachedUserId = id;
    return id;
  }

  String _generateId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    // Simple UUID-v4-shaped string, good enough as an opaque identifier
    // (doesn't need to be a *real* RFC4122 UUID for our purposes).
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4${hex.substring(13, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Loads the profile: LOCAL CACHE FIRST, backend as a background sync.
  ///
  /// This used to check the backend first and fall back to local cache
  /// only on failure. That was backwards in practice: if the backend
  /// ever had an older/emptier profile than what's on-device (e.g. a
  /// previous saveProfile()'s background PUT silently failed due to a
  /// network hiccup, CORS, or the endpoint not being fully live yet),
  /// the *next* loadProfile() would happily fetch that stale backend
  /// copy and overwrite fresh local writes -- so a PCOS result or
  /// contraception choice saved seconds ago could vanish from the
  /// Diary the moment you reopened it, even though it was safely
  /// sitting in local storage the whole time.
  ///
  /// Now: local cache is returned immediately (it's authoritative for
  /// "what did this device just do"), and a backend fetch happens in
  /// the background purely to pick up data saved from a *different*
  /// device -- and even then, it's only adopted if it's actually newer
  /// than what's already local (compared via lastUpdated), so a stale
  /// backend record can never clobber a fresher local one.
  Future<HealthProfile> loadProfile() async {
    final userId = await getDeviceId();

    final local = await _loadFromCache(userId);

    // Fire-and-forget: sync from backend if it turns out to be newer.
    // Intentionally not awaited -- the UI should never block on this,
    // and _refreshFromBackendIfNewer() safely no-ops on any failure.
    unawaited(_refreshFromBackendIfNewer(userId, local));

    if (local != null) {
      _cachedProfile = local;
      return local;
    }

    // No local cache at all (first-ever launch on this device) -- in
    // this one case it's worth waiting on the network, since there's
    // nothing better to show yet.
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/profile/$userId');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final profile = HealthProfile.fromJson(json);
        await _cacheLocally(profile);
        _cachedProfile = profile;
        return profile;
      }
    } catch (_) {
      // Network unavailable / server down / endpoint not live yet --
      // fall through to a blank profile below.
    }

    final blank = HealthProfile.empty(userId);
    _cachedProfile = blank;
    return blank;
  }

  /// Background helper for loadProfile(): fetches the backend copy and
  /// only adopts it (overwriting local cache + in-memory cache) if it
  /// is strictly newer than what's already local. This is what makes
  /// cross-device sync safe without risking data loss on this device.
  Future<void> _refreshFromBackendIfNewer(
    String userId,
    HealthProfile? local,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/profile/$userId');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final remote = HealthProfile.fromJson(json);

      if (local == null || remote.lastUpdated.isAfter(local.lastUpdated)) {
        await _cacheLocally(remote);
        _cachedProfile = remote;
      }
    } catch (_) {
      // Best-effort background sync -- any failure here is silent and
      // harmless, since the local copy is already what's showing.
    }
  }

  /// Saves the profile: writes to local cache immediately (so the UI
  /// never waits on the network), then pushes to the backend in the
  /// background. If the backend call fails, the local cache still has
  /// the update -- the next successful loadProfile()/saveProfile() call
  /// will resync.
  Future<void> saveProfile(HealthProfile profile) async {
    _cachedProfile = profile;
    await _cacheLocally(profile);

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/profile/${profile.userId}');
      await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(profile.toJson()),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Background sync failed silently -- local cache is still correct,
      // and will be retried on the next saveProfile()/loadProfile() call.
      // (If you want the user to see a "not synced" indicator, surface
      // this instead of swallowing it.)
    }
  }

  /// Convenience: apply a partial update without needing the caller to
  /// hand back a full HealthProfile. Example:
  ///   await service.updateProfile((p) => p.copyWith(
  ///     lifestyle: p.lifestyle.copyWith(regularExercise: true),
  ///   ));
  Future<HealthProfile> updateProfile(
    HealthProfile Function(HealthProfile current) updater,
  ) async {
    final current = _cachedProfile ?? await loadProfile();
    final updated = updater(current);
    await saveProfile(updated);
    return updated;
  }

  /// Appends one turn to the AI conversation log and saves. Kept as a
  /// dedicated method since this will be called frequently once the AI
  /// chat screen exists, and callers shouldn't need to hand-roll the
  /// list-append logic every time.
  Future<HealthProfile> appendConversationEntry(String role, String message) {
    return updateProfile((p) {
      final updatedLog = List<ConversationEntry>.from(p.conversationLog)
        ..add(
          ConversationEntry(
            timestamp: DateTime.now(),
            role: role,
            message: message,
          ),
        );
      return p.copyWith(conversationLog: updatedLog);
    });
  }

  /// Appends a new PCOS result to history (call this right after a
  /// successful /predict call in pcos_screen.dart) instead of only
  /// keeping the latest result in local widget state.
  Future<HealthProfile> appendPcosResult({
    required String prediction,
    required double pcosProbability,
    required String modelUsed,
  }) {
    return updateProfile((p) {
      final updatedHistory = List<PcosCheckResult>.from(p.pcosHistory)
        ..add(
          PcosCheckResult(
            date: DateTime.now(),
            prediction: prediction,
            pcosProbability: pcosProbability,
            modelUsed: modelUsed,
          ),
        );
      return p.copyWith(pcosHistory: updatedHistory);
    });
  }

  Future<void> _cacheLocally(HealthProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localProfileKey, jsonEncode(profile.toJson()));
  }

  Future<HealthProfile?> _loadFromCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localProfileKey);
    if (raw == null) return null;
    try {
      return HealthProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
