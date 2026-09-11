import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_saheli/theme/app_theme.dart';

void main() {
  test('dark and light themes expose expected contrast colors', () {
    final light = buildLightTheme();
    final dark = buildDarkTheme();

    expect(light.colorScheme.surface, AppColors.surface);
    expect(light.colorScheme.onSurface, AppColors.textPrimary);

    expect(dark.brightness, Brightness.dark);
    expect(dark.colorScheme.surface, AppColors.darkSurface);
    expect(dark.colorScheme.onSurface, AppColors.darkTextPrimary);
  });
}
