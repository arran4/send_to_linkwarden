import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:send_to_linkwarden/view/main_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:send_to_linkwarden/state/dark_mode_notifier.dart';

void main() {
  Widget createWidgetUnderTest() {
    return MaterialApp(
      routes: {
        'userInstance/manage': (context) =>
            const Scaffold(body: Text('Manage Instances View')),
      },
      home: const Scaffold(
        drawer: MainDrawer(),
        body: Center(child: Text('Home')),
      ),
    );
  }

  test('shouldShowQuit predicate', () {
    expect(
      shouldShowQuit(isWeb: true, platform: TargetPlatform.windows),
      isFalse,
    );
    expect(
      shouldShowQuit(isWeb: true, platform: TargetPlatform.android),
      isFalse,
    );

    expect(
      shouldShowQuit(isWeb: false, platform: TargetPlatform.windows),
      isTrue,
    );
    expect(
      shouldShowQuit(isWeb: false, platform: TargetPlatform.linux),
      isTrue,
    );
    expect(
      shouldShowQuit(isWeb: false, platform: TargetPlatform.macOS),
      isTrue,
    );

    expect(
      shouldShowQuit(isWeb: false, platform: TargetPlatform.android),
      isFalse,
    );
    expect(shouldShowQuit(isWeb: false, platform: TargetPlatform.iOS), isFalse);
  });

  testWidgets(
    'Drawer shows Linkwarden Settings header and Manage Instances route navigates',
    (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      ScaffoldState scaffoldState = tester.firstState(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Linkwarden Settings'), findsOneWidget);

      await tester.tap(find.text('Manage Instances'));
      await tester.pumpAndSettle();

      expect(find.text('Manage Instances View'), findsOneWidget);
    },
  );

  testWidgets('Drawer Quit button is visible on Desktop Windows', (
    WidgetTester tester,
  ) async {
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      await tester.pumpWidget(createWidgetUnderTest());
      final ScaffoldState scaffoldState = tester.firstState(
        find.byType(Scaffold),
      );
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Quit'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Drawer Quit button is visible on Desktop Linux', (
    WidgetTester tester,
  ) async {
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      await tester.pumpWidget(createWidgetUnderTest());
      final ScaffoldState scaffoldState = tester.firstState(
        find.byType(Scaffold),
      );
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Quit'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Drawer Quit button is visible on Desktop macOS', (
    WidgetTester tester,
  ) async {
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      await tester.pumpWidget(createWidgetUnderTest());
      final ScaffoldState scaffoldState = tester.firstState(
        find.byType(Scaffold),
      );
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Quit'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Drawer Quit button is absent on Mobile Android', (
    WidgetTester tester,
  ) async {
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await tester.pumpWidget(createWidgetUnderTest());
      final ScaffoldState scaffoldState = tester.firstState(
        find.byType(Scaffold),
      );
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Quit'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Drawer Quit button is absent on Mobile iOS', (
    WidgetTester tester,
  ) async {
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(createWidgetUnderTest());
      final ScaffoldState scaffoldState = tester.firstState(
        find.byType(Scaffold),
      );
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Quit'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Drawer theme control updates themeModeNotifier', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(createWidgetUnderTest());

    ScaffoldState scaffoldState = tester.firstState(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Theme'), findsOneWidget);

    // Tap the dropdown
    await tester.tap(find.byType(DropdownButton<ThemeMode>));
    await tester.pumpAndSettle();

    // Select Dark
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(darkModeNotifier.value, ThemeMode.dark);

    // Open dropdown again
    await tester.tap(find.byType(DropdownButton<ThemeMode>));
    await tester.pumpAndSettle();

    // Select Light
    await tester.tap(find.text('Light').last);
    await tester.pumpAndSettle();

    expect(darkModeNotifier.value, ThemeMode.light);
  });
}
