import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

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
