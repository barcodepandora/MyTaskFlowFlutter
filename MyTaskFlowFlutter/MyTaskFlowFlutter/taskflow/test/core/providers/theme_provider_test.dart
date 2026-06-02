import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/core/providers/theme_provider.dart';

void main() {
  group('ThemeNotifier', () {
    test('estado inicial es ThemeMode.system cuando no hay preferencia', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(prefs);
      expect(notifier.state, ThemeMode.system);
    });

    test('carga ThemeMode.dark desde SharedPreferences al inicializar', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(prefs);
      expect(notifier.state, ThemeMode.dark);
    });

    test('carga ThemeMode.light desde SharedPreferences al inicializar', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(prefs);
      expect(notifier.state, ThemeMode.light);
    });

    test('setThemeMode actualiza estado y persiste en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(prefs);

      await notifier.setThemeMode(ThemeMode.light);

      expect(notifier.state, ThemeMode.light);
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('setThemeMode(dark) persiste "dark"', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(prefs);

      await notifier.setThemeMode(ThemeMode.dark);

      expect(notifier.state, ThemeMode.dark);
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('setThemeMode(system) persiste "system"', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ThemeNotifier(prefs);

      await notifier.setThemeMode(ThemeMode.system);

      expect(notifier.state, ThemeMode.system);
      expect(prefs.getString('theme_mode'), 'system');
    });
  });
}
