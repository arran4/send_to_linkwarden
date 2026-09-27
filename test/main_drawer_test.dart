import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:send_to_linkwarden/view/main_drawer.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: Scaffold(
        drawer: MainDrawer(),
        body: Center(child: Text('Home')),
      ),
    );
  }

  testWidgets('Drawer shows Linkwarden Settings header and Manage Instances', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    ScaffoldState scaffoldState = tester.firstState(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Linkwarden Settings'), findsOneWidget);
    expect(find.text('Manage Instances'), findsOneWidget);
  });

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
