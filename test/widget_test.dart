import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_saheli/main.dart';
import 'package:wellness_saheli/providers/cycle_provider.dart';
import 'package:wellness_saheli/screens/settings_screen.dart';

void main() {
  SharedPreferences.setMockInitialValues({});
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const WellnessSaheliApp());
    expect(find.byType(WellnessSaheliApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Settings logout clears the local session', (tester) async {
    final provider = CycleProvider();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await provider.login('Flutter Tester', userId: '1', token: 'test-token');

    await tester.pumpWidget(
      ChangeNotifierProvider<CycleProvider>.value(
        value: provider,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    final logoutButton = find.text('Log Out').first;
    await tester.ensureVisible(logoutButton);
    await tester.tap(logoutButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Log Out').last);
    await tester.pump(const Duration(milliseconds: 300));

    expect(provider.isLoggedIn, isFalse);
    expect(provider.authToken, isNull);
  });
}
