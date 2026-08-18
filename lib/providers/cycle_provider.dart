import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cycle_data.dart';
import '../models/daily_log.dart';

class CycleProvider extends ChangeNotifier {
  CycleData _cycleData = CycleData(
    lastPeriodStart: DateTime.now().subtract(const Duration(days: 14)),
  );

  bool _isLoaded = false;
  bool _remindersEnabled = true;

  // --- Auth / profile state ---
  bool _isLoggedIn = false;
  String _userName = '';

  // Accounts now live on the backend server (see /signup, /signin,
  // /reset_password) so they survive app reinstalls and work across
  // devices. Only the "remember me" flag + name are cached locally
  // below, purely so the splash screen can skip sign-in on relaunch.
  static const String _authBaseUrl =
      'https://areeshasadaf56.pythonanywhere.com';

  Map<String, DailyLog> _dailyLogs = {};

  DateTime? _selectedPeriodDate;

  CycleData get cycleData => _cycleData;
  bool get isLoaded => _isLoaded;
  Map<String, DailyLog> get dailyLogs => _dailyLogs;
  DateTime? get selectedPeriodDate => _selectedPeriodDate;

  int get currentCycleDay => _cycleData.getCurrentCycleDay();
  String get currentPhase => _cycleData.getPhase();
  int get daysUntilNextPeriod => _cycleData.daysUntilNextPeriod();
  int get cycleLength => _cycleData.cycleLength;
  int get periodDuration => _cycleData.periodDuration;

  bool get remindersEnabled => _remindersEnabled;

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;

  CycleProvider() {
    _loadData();
  }

  String _keyFor(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DailyLog getLogFor(DateTime date) {
    return _dailyLogs[_keyFor(date)] ?? DailyLog();
  }

  bool isSelectedDay(DateTime date) {
    if (_selectedPeriodDate == null) return false;
    return _isSameDay(_selectedPeriodDate!, date);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final lastPeriodMillis = prefs.getInt('lastPeriodStart');
    final cycleLength = prefs.getInt('cycleLength');
    final periodDuration = prefs.getInt('periodDuration');

    if (lastPeriodMillis != null) {
      _cycleData = CycleData(
        lastPeriodStart: DateTime.fromMillisecondsSinceEpoch(lastPeriodMillis),
        cycleLength: cycleLength ?? 28,
        periodDuration: periodDuration ?? 5,
      );
      _selectedPeriodDate = _cycleData.lastPeriodStart;
    }

    final logsJson = prefs.getString('dailyLogs');
    if (logsJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(logsJson);
        _dailyLogs = decoded.map(
          (key, value) => MapEntry(key, DailyLog.fromJson(value)),
        );
      } catch (_) {
        _dailyLogs = {};
      }
    }

    _remindersEnabled = prefs.getBool('remindersEnabled') ?? true;

    // Restore auth/profile state so a returning user skips sign-in.
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userName = prefs.getString('userName') ?? '';

    _isLoaded = true;
    notifyListeners();
  }

  void toggleReminders(bool value) async {
    _remindersEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remindersEnabled', value);
  }

  /// Call on successful sign in / sign up. Persists both the logged-in
  /// flag and the name so "Hello, {name}" survives an app restart.
  Future<void> login(String name) async {
    _isLoggedIn = true;
    _userName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userName', name);
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  /// Creates a new account on the server. Returns null on success, or
  /// an error message string on failure (e.g. email already taken, or
  /// no internet connection).
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_authBaseUrl/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': _normalizeEmail(email),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return body['detail'] ?? 'Something went wrong. Please try again.';
      }

      await login(body['name'] ?? name);
      return null;
    } catch (_) {
      return 'Could not reach the server. Please check your internet connection and try again.';
    }
  }

  /// Validates credentials against the server. Returns null on success,
  /// or an error message string on failure.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_authBaseUrl/signin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _normalizeEmail(email),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return body['detail'] ?? 'Something went wrong. Please try again.';
      }

      await login(body['name'] ?? '');
      return null;
    } catch (_) {
      return 'Could not reach the server. Please check your internet connection and try again.';
    }
  }

  /// Resets the password for an existing account on the server. Returns
  /// null on success, or an error message string on failure.
  Future<String?> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_authBaseUrl/reset_password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _normalizeEmail(email),
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        return body['detail'] ?? 'Something went wrong. Please try again.';
      }

      return null;
    } catch (_) {
      return 'Could not reach the server. Please check your internet connection and try again.';
    }
  }

  /// Call from the Settings logout button. Clears the flag so Splash
  /// routes back to Sign In next launch, but keeps cycle/log data intact.
  Future<void> logout() async {
    _isLoggedIn = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }

  void updateUserName(String name) async {
    _userName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
  }

  Future<void> _saveCycleData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'lastPeriodStart',
      _cycleData.lastPeriodStart.millisecondsSinceEpoch,
    );
    await prefs.setInt('cycleLength', _cycleData.cycleLength);
    await prefs.setInt('periodDuration', _cycleData.periodDuration);
  }

  Future<void> _saveDailyLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> encoded = _dailyLogs.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await prefs.setString('dailyLogs', jsonEncode(encoded));
  }

  void updateLastPeriodStart(DateTime date) {
    _cycleData.lastPeriodStart = date;
    _saveCycleData();
    notifyListeners();
  }

  void updateCycleLength(int length) {
    _cycleData.cycleLength = length;
    _saveCycleData();
    notifyListeners();
  }

  void updatePeriodDuration(int duration) {
    _cycleData.periodDuration = duration;
    _saveCycleData();
    notifyListeners();
  }

  void logPeriodStartToday() {
    selectPeriodDate(DateTime.now());
  }

  void selectPeriodDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);

    if (_selectedPeriodDate != null) {
      final oldKey = _keyFor(_selectedPeriodDate!);
      if (_dailyLogs.containsKey(oldKey)) {
        _dailyLogs[oldKey]!.isPeriodDay = false;
      }
    }

    if (_selectedPeriodDate != null &&
        _isSameDay(_selectedPeriodDate!, normalized)) {
      _selectedPeriodDate = null;
    } else {
      _selectedPeriodDate = normalized;
      final newKey = _keyFor(normalized);
      final existing = _dailyLogs[newKey] ?? DailyLog();
      existing.isPeriodDay = true;
      _dailyLogs[newKey] = existing;

      _cycleData.lastPeriodStart = normalized;
      _saveCycleData();
    }

    _saveDailyLogs();
    notifyListeners();
  }

  void logMood(DateTime date, String mood) {
    final key = _keyFor(date);
    final existing = _dailyLogs[key] ?? DailyLog();
    existing.mood = mood;
    _dailyLogs[key] = existing;
    _saveDailyLogs();
    notifyListeners();
  }

  void logSymptoms(DateTime date, List<String> symptoms) {
    final key = _keyFor(date);
    final existing = _dailyLogs[key] ?? DailyLog();
    existing.symptoms = symptoms;
    _dailyLogs[key] = existing;
    _saveDailyLogs();
    notifyListeners();
  }

  void logFlowIntensity(DateTime date, String intensity) {
    final key = _keyFor(date);
    final existing = _dailyLogs[key] ?? DailyLog();
    existing.flowIntensity = intensity;
    _dailyLogs[key] = existing;
    _saveDailyLogs();
    notifyListeners();
  }
}
