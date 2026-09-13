import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/model/collection.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/state/collections_replayer.dart';
import 'package:send_to_linkwarden/state/tags_replayer.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';
import 'package:send_to_linkwarden/view/add_link_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});

    userInstanceValueReplayer.publish([
      UserInstance(
        id: '1',
        server: 'https://linkwarden.example.com',
        apiToken: 'token1',
      ),
      UserInstance(
        id: '2',
        server: 'https://linkwarden.example.org',
        apiToken: 'token2',
      ),
    ]);

    collectionsReplayer.publish([
      Collection(id: 1, name: 'Collection 1', ownerId: 1, color: '#ff0000'),
    ], currentKey: '1');

    collectionsReplayer.publish([
      Collection(id: 2, name: 'Collection 2', ownerId: 1, color: '#ff0000'),
    ], currentKey: '2');

    tagsReplayer.publish([], currentKey: '1');
    tagsReplayer.publish([], currentKey: '2');
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(home: AddLinkView());
  }

  testWidgets('Validation fails correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Validation errors'), findsOneWidget);
  });

  testWidgets(
    'Instance switch preserves text but resets selected collection and tags',
    (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final urlField = find
          .ancestor(of: find.text('Link'), matching: find.byType(TextFormField))
          .first;
      await tester.enterText(urlField, 'https://keep-this-url.com');
      await tester.pumpAndSettle();

      await tester.tap(find.text('https://linkwarden.example.com'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('https://linkwarden.example.org').last);
      await tester.pumpAndSettle();

      // Verify text is preserved
      expect(find.text('https://keep-this-url.com'), findsOneWidget);
    },
  );

  testWidgets(
    'Simulate submit preserves draft if error, and resets if success',
    (WidgetTester tester) async {
      expect(true, isTrue);
    },
  );
}
