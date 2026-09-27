import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:send_to_linkwarden/view/main_drawer.dart';

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
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    await tester.pumpWidget(createWidgetUnderTest());
    ScaffoldState scaffoldState = tester.firstState(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Quit'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Drawer Quit button is visible on Desktop Linux', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    await tester.pumpWidget(createWidgetUnderTest());
    ScaffoldState scaffoldState = tester.firstState(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Quit'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Drawer Quit button is visible on Desktop macOS', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    await tester.pumpWidget(createWidgetUnderTest());
    ScaffoldState scaffoldState = tester.firstState(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Quit'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Drawer Quit button is absent on Mobile Android', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await tester.pumpWidget(createWidgetUnderTest());
    ScaffoldState scaffoldState = tester.firstState(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Quit'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Drawer Quit button is absent on Mobile iOS', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await tester.pumpWidget(createWidgetUnderTest());
    ScaffoldState scaffoldState = tester.firstState(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Quit'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
