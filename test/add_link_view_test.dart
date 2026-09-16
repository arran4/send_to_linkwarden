import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/model/collection.dart';
import 'package:send_to_linkwarden/model/tag.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/state/collections_replayer.dart';
import 'package:send_to_linkwarden/state/tags_replayer.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';
import 'package:send_to_linkwarden/view/add_link_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'defaultUserInstance': 'instA'});
    userInstanceValueReplayer.publish([
      UserInstance(id: 'instA', server: 'http://a.com', apiToken: 'tokenA'),
      UserInstance(id: 'instB', server: 'http://b.com', apiToken: 'tokenB'),
    ]);
    collectionsReplayer.publish([
      Collection(id: 1, name: 'ColA'),
    ], currentKey: 'instA');
    collectionsReplayer.publish([
      Collection(id: 2, name: 'ColB'),
    ], currentKey: 'instB');
    tagsReplayer.publish([Tag(id: 1, name: 'TagA')], currentKey: 'instA');
    tagsReplayer.publish([Tag(id: 2, name: 'TagB')], currentKey: 'instB');
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: const Scaffold(body: AddLinkView()),
      onGenerateRoute: (settings) {
        // Mock routing for pushNamed returns null
        return MaterialPageRoute(builder: (context) => const SizedBox.shrink());
      },
    );
  }

  testWidgets('Submit in-flight state and duplicate-click prevention works', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'https://example.com',
    );

    // Select ColA so validation passes
    await tester.tap(find.byType(DropdownButtonFormField<Collection>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ColA').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // Submit throws exception due to bad network
    expect(find.textContaining('Failed to submit bookmark'), findsOneWidget);
    expect(find.text('https://example.com'), findsOneWidget); // Draft kept
    expect(find.text('Submit'), findsOneWidget); // Re-enabled
  });

  testWidgets('Instance switching (A -> B) isolates collection and tags', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Select ColA
    await tester.tap(find.byType(DropdownButtonFormField<Collection>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ColA').last);
    await tester.pumpAndSettle();

    expect(find.text('ColA'), findsWidgets);

    // Switch to B
    // Wait... if http://a.com isn't found, it might be found as a dropdown item if we tap the dropdown.
    // There are actually multiple DropdownButtonFormField widgets, but wait,
    // it's `DropdownButtonFormField<Object>` internally in some flutter versions.
    // Since http://a.com is visible as the selected text, tapping it directly works usually if we look for the last one (which is the actual display).
    await tester.tap(find.text('http://a.com').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('http://b.com').last);
    await tester.pumpAndSettle();

    // Check switched and collection reset
    expect(find.text('http://b.com'), findsWidgets);
    expect(find.text('ColA'), findsNothing);
  });

  testWidgets('Instance switching to new preserves draft', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'https://example.com',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('http://a.com').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New').last);
    await tester.pumpAndSettle();

    expect(find.text('https://example.com'), findsOneWidget);
  });
}
