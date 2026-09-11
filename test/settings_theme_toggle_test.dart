import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_saheli/providers/cycle_provider.dart';
import 'package:wellness_saheli/screens/settings_screen.dart';
import 'package:wellness_saheli/theme/app_theme.dart';

void main() {
  testWidgets('settings appearance toggle updates theme mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = CycleProvider();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await tester.pumpWidget(
      ChangeNotifierProvider<CycleProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Follow system'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(provider.themeMode, ThemeMode.dark);
  });
}
