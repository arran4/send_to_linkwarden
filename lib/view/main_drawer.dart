import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:send_to_linkwarden/state/dark_mode_notifier.dart';

bool shouldShowQuit({required bool isWeb, required TargetPlatform platform}) {
  if (isWeb) return false;
  return platform == TargetPlatform.windows ||
      platform == TargetPlatform.linux ||
      platform == TargetPlatform.macOS;
}

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(child: Text('Linkwarden Settings')),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Manage Instances'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, 'userInstance/manage');
            },
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: darkModeNotifier,
            builder: (context, ThemeMode currentTheme, _) {
              return ListTile(
                leading: Icon(
                  currentTheme == ThemeMode.light
                      ? Icons.light_mode
                      : currentTheme == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.brightness_auto,
                ),
                title: const Text('Theme'),
                trailing: DropdownButton<ThemeMode>(
                  value: currentTheme,
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      setDarkMode(newValue);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                ),
              );
            },
          ),
          if (shouldShowQuit(isWeb: kIsWeb, platform: defaultTargetPlatform))
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Quit'),
              onTap: () {
                SystemNavigator.pop();
              },
            ),
        ],
      ),
    );
  }
}
