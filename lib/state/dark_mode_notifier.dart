import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final darkModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<ThemeMode> loadDarkMode() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (prefs.containsKey('themeMode')) {
    final themeString = prefs.getString('themeMode');
    if (themeString == 'light') {
      darkModeNotifier.value = ThemeMode.light;
    } else if (themeString == 'dark') {
      darkModeNotifier.value = ThemeMode.dark;
    } else {
      darkModeNotifier.value = ThemeMode.system;
    }
  } else if (prefs.containsKey('darkMode')) {
    // Migration from old boolean preference
    bool isDark = prefs.getBool('darkMode') ?? false;
    darkModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    // Save the new format and remove the old
    await prefs.setString('themeMode', isDark ? 'dark' : 'light');
    await prefs.remove('darkMode');
  } else {
    darkModeNotifier.value = ThemeMode.system;
  }

  return darkModeNotifier.value;
}

Future<void> setDarkMode(ThemeMode newValue) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  darkModeNotifier.value = newValue;
  String themeString = 'system';
  if (newValue == ThemeMode.light) {
    themeString = 'light';
  } else if (newValue == ThemeMode.dark) {
    themeString = 'dark';
  }
  await prefs.setString('themeMode', themeString);
}
