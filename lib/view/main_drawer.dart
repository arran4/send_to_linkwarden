import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(child: Text('Options')),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Manage Instances'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, 'userInstance/manage');
            },
          ),
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
