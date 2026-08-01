import 'dart:convert';
import 'package:flutter/material.dart';
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

  // Local "accounts" store: { email -> {password, name} }.
  // NOTE: This is on-device only storage for offline/demo use — there is
  // no real backend yet, and the password is only lightly obfuscated
  // (not cryptographically secure). Good enough so Sign In actually
  // checks credentials and Forgot Password can reset them, but this
  // should be swapped for real server-side auth before shipping.
  Map<String, Map<String, String>> _accounts = {};

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

    // Restore the local accounts store (email -> {password, name}).
    final accountsJson = prefs.getString('accounts');
    if (accountsJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(accountsJson);
        _accounts = decoded.map(
          (key, value) => MapEntry(key, Map<String, String>.from(value)),
        );
      } catch (_) {
        _accounts = {};
      }
    }

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

  // Lightweight on-device obfuscation — NOT real encryption. Fine for a
  // local-only demo account store, but swap for real hashing (or better,
  // a real backend) before this ships to real users.
  String _obscure(String password) => base64Encode(utf8.encode(password));

  Future<void> _saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accounts', jsonEncode(_accounts));
  }

  /// Creates a new local account. Returns null on success, or an
  /// error message string if the email is already registered.
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final key = _normalizeEmail(email);

    if (_accounts.containsKey(key)) {
      return 'An account with this email already exists. Try signing in instead.';
    }

    _accounts[key] = {'password': _obscure(password), 'name': name};
    await _saveAccounts();

    await login(name);
    return null;
  }

  /// Validates credentials against the local account store. Returns
  /// null on success, or an error message string on failure.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    final key = _normalizeEmail(email);
    final account = _accounts[key];

    if (account == null) {
      return 'No account found for this email. Try signing up first.';
    }

    if (account['password'] != _obscure(password)) {
      return 'Incorrect password. Please try again.';
    }

    await login(account['name'] ?? '');
    return null;
  }

  /// Resets the password for an existing local account. Returns null on
  /// success, or an error message string if no account exists for that
  /// email.
  Future<String?> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final key = _normalizeEmail(email);
    final account = _accounts[key];

    if (account == null) {
      return 'No account found for this email.';
    }

    account['password'] = _obscure(newPassword);
    _accounts[key] = account;
    await _saveAccounts();
    return null;
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
