import 'dart:async';

import 'package:flutter/material.dart';
import 'package:send_to_linkwarden/state/dark_mode_notifier.dart';
import 'package:send_to_linkwarden/view/add_collection_view.dart';
import 'package:send_to_linkwarden/view/add_edit_user_instance_view.dart';
import 'package:send_to_linkwarden/view/select_tags_view.dart';
import 'package:send_to_linkwarden/view/add_link_view.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  runApp(const SendToLinkwardenApp());
}

class SendToLinkwardenApp extends StatefulWidget {
  const SendToLinkwardenApp({super.key});

  @override
  State<SendToLinkwardenApp> createState() => _SendToLinkwardenAppState();
}

class _SendToLinkwardenAppState extends State<SendToLinkwardenApp> {
  late StreamSubscription _intentSub;
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    loadDarkMode();
    // Listen to media sharing coming from outside the app while the app is in the memory.
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) async {
      for (SharedMediaFile sharedMediaFile in value) {
        await navigatorKey.currentState?.pushNamed("link/new", arguments: AddLinkViewArguments(
          name: "",
          description: sharedMediaFile.message,
          link: sharedMediaFile.path,
        ));
      }
    }, onError: (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Media share error $err')),
        );
      }
      print("getIntentDataStream error: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) async {
      for (SharedMediaFile sharedMediaFile in value) {
        await navigatorKey.currentState?.pushNamed("link/new", arguments: AddLinkViewArguments(
          name: "",
          description: sharedMediaFile.message,
          link: sharedMediaFile.path,
        ));
      }
      // Tell the library that we are done processing the intent.
      ReceiveSharingIntent.instance.reset();
    });
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: darkModeNotifier,
        builder: (BuildContext context, bool isDark, Widget? child) {
          return MaterialApp(
            title: 'Send To Linkwarden',
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
              useMaterial3: true,
            ),
            navigatorKey: navigatorKey,
            darkTheme: ThemeData.dark(
              useMaterial3: true,
            ),
            routes: {
              "/": (BuildContext context) => const AddLinkView(),
              "link/new": (BuildContext context) => AddLinkView(arguments: ModalRoute.of(context)?.settings.arguments as AddLinkViewArguments?),
              "tags/select": (BuildContext context) => SelectTagsView(arguments: ModalRoute.of(context)?.settings.arguments as SelectTagsViewArguments?),
              "collection/new": (BuildContext context) => AddCollectionView(arguments: ModalRoute.of(context)?.settings.arguments as AddCollectionViewArguments?),
              "userInstance/newEdit": (BuildContext context) => AddEditUserInstanceView(arguments: ModalRoute.of(context)?.settings.arguments as AddEditUserInstanceViewArguments?),
            },
          );
        });
  }
}

