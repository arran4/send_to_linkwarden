import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final defaultUserInstanceNotifier = ValueNotifier<String?>(null);

Future<String?> loadDefaultUserInstance() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? newValue = prefs.getString('defaultUserInstance');
  defaultUserInstanceNotifier.value = newValue;
  return newValue;
}

Future<void> setDefaultUserInstance(String? newValue) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  defaultUserInstanceNotifier.value = newValue;
  if (newValue is String) {
    await prefs.setString('defaultUserInstance', newValue);
  } else {
    await prefs.remove('defaultUserInstance');
  }
}
