import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_saheli/providers/cycle_provider.dart';

void main() {
  test('loads persisted dark theme mode and persists updates', () async {
    SharedPreferences.setMockInitialValues({'themeMode': 'dark'});

    final provider = CycleProvider();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(provider.themeMode, ThemeMode.dark);

    await provider.setThemeMode(ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();

    expect(provider.themeMode, ThemeMode.light);
    expect(prefs.getString('themeMode'), 'light');
  });
}
