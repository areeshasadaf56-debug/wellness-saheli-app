import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'providers/cycle_provider.dart';

void main() {
  // --- TEMPORARY DIAGNOSTIC: shows the real error on-screen instead of a
  // blank page whenever a widget throws while building. Once the blank
  // -screen bug is found and fixed, this whole block (down to the
  // runZonedGuarded call) can be deleted and replaced with a plain
  // `runApp(const WellnessSaheliApp());`.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFFFF0F0),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          'WIDGET ERROR:\n\n${details.exceptionAsString()}\n\n${details.stack}',
          style: const TextStyle(color: Color(0xFFB00020), fontSize: 11),
        ),
      ),
    );
  };

  runZonedGuarded(() => runApp(const WellnessSaheliApp()), (error, stack) {
    // Uncaught errors outside the widget tree (e.g. in an async call)
    // land here instead of silently vanishing.
    debugPrint('UNCAUGHT ERROR: $error\n$stack');
  });
}

class WellnessSaheliApp extends StatelessWidget {
  const WellnessSaheliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CycleProvider(),
      child: Consumer<CycleProvider>(
        builder: (context, cycle, _) {
          return MaterialApp(
            title: 'Wellness Saheli',
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: cycle.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
