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

  testWidgets('Drawer shows Linkwarden Settings header', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    ScaffoldState scaffoldState = tester.firstState(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Linkwarden Settings'), findsOneWidget);
    expect(find.text('Manage Instances'), findsOneWidget);
  });

  testWidgets('Drawer Quit button visibility check', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    ScaffoldState scaffoldState = tester.firstState(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    debugPrint('Test platform: \$defaultTargetPlatform, kIsWeb: \$kIsWeb');

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      expect(find.text('Quit'), findsOneWidget);
    } else {
      expect(find.text('Quit'), findsNothing);
    }
  });
}
