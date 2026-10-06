import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:send_to_linkwarden/state/dark_mode_notifier.dart';

void main() {
  test('loadDarkMode defaults to system', () async {
    SharedPreferences.setMockInitialValues({});
    final theme = await loadDarkMode();
    expect(theme, ThemeMode.system);
    expect(darkModeNotifier.value, ThemeMode.system);
  });

  test('loadDarkMode migrates old boolean true to dark', () async {
    SharedPreferences.setMockInitialValues({'darkMode': true});
    final theme = await loadDarkMode();
    expect(theme, ThemeMode.dark);
    expect(darkModeNotifier.value, ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('darkMode'), false);
    expect(prefs.getString('themeMode'), 'dark');
  });

  test('loadDarkMode migrates old boolean false to light', () async {
    SharedPreferences.setMockInitialValues({'darkMode': false});
    final theme = await loadDarkMode();
    expect(theme, ThemeMode.light);
    expect(darkModeNotifier.value, ThemeMode.light);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('darkMode'), false);
    expect(prefs.getString('themeMode'), 'light');
  });

  test('loadDarkMode prefers themeMode string over boolean', () async {
    SharedPreferences.setMockInitialValues({
      'darkMode': false,
      'themeMode': 'dark',
    });
    final theme = await loadDarkMode();
    expect(theme, ThemeMode.dark);
    expect(darkModeNotifier.value, ThemeMode.dark);
  });

  test('setDarkMode saves string and updates notifier', () async {
    SharedPreferences.setMockInitialValues({});
    await setDarkMode(ThemeMode.light);
    expect(darkModeNotifier.value, ThemeMode.light);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('themeMode'), 'light');

    await setDarkMode(ThemeMode.dark);
    expect(darkModeNotifier.value, ThemeMode.dark);
    expect(prefs.getString('themeMode'), 'dark');

    await setDarkMode(ThemeMode.system);
    expect(darkModeNotifier.value, ThemeMode.system);
    expect(prefs.getString('themeMode'), 'system');
  });
}
