import 'package:flutter/material.dart';
import 'package:linkwarden_mobile/state/dark_mode_notifier.dart';
import 'package:linkwarden_mobile/view/default.dart';
import 'package:linkwarden_mobile/view/main.dart';

void main() {
  runApp(const LinkwardenMobileApp());
}

class LinkwardenMobileApp extends StatelessWidget {
  const LinkwardenMobileApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: darkModeNotifier,
        builder: (BuildContext context, bool isDark, Widget? child) {
          return MaterialApp(
            title: 'Linkwarden Mobile',
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
              useMaterial3: true,
            ),
            darkTheme: ThemeData.dark(
              useMaterial3: true,
            ),
            routes: {
              "/": (BuildContext context) => const MainView(),
            },
          );
        });
  }
}

