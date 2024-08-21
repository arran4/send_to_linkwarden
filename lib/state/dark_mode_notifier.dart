import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

final darkModeNotifier = ValueNotifier<bool>(false);

Future<bool> loadDarkMode() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  bool newValue = prefs.getBool('darkMode') ?? false;
  darkModeNotifier.value = newValue;
  return newValue;
}

Future<void> setDarkMode(bool newValue) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  darkModeNotifier.value = newValue;
  await prefs.setBool('darkMode', newValue);
}
