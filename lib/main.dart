import 'package:flutter/material.dart';
import 'package:linkwarden_mobile/state/dark_mode_notifier.dart';
import 'package:linkwarden_mobile/view/add_collection_view.dart';
import 'package:linkwarden_mobile/view/add_edit_user_instance_view.dart';
import 'package:linkwarden_mobile/view/select_tags_view.dart';
import 'package:linkwarden_mobile/view/template_view.dart';
import 'package:linkwarden_mobile/view/add_link_view.dart';

void main() {
  runApp(const LinkwardenMobileApp());
}

class LinkwardenMobileApp extends StatelessWidget {
  const LinkwardenMobileApp({super.key});


  @override
  StatelessElement createElement() {
    loadDarkMode();
    return super.createElement();
  }


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
              "/": (BuildContext context) => const AddLinkView(),
              "link/new": (BuildContext context) => const AddLinkView(),
              "tags/select": (BuildContext context) => SelectTagsView(arguments: ModalRoute.of(context)?.settings.arguments as SelectTagsViewArguments?),
              "collection/new": (BuildContext context) => AddCollectionView(arguments: ModalRoute.of(context)?.settings.arguments as AddCollectionViewArguments?),
              "userInstance/newEdit": (BuildContext context) => AddEditUserInstanceView(arguments: ModalRoute.of(context)?.settings.arguments as AddEditUserInstanceViewArguments?),
            },
          );
        });
  }
}

