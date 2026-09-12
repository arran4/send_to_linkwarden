import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/model/collection.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/state/collections_replayer.dart';
import 'package:send_to_linkwarden/state/tags_replayer.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';
import 'package:send_to_linkwarden/state/default_user_instance.dart';
import 'package:send_to_linkwarden/view/add_link_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    userInstanceValueReplayer.publish([]);
    collectionsReplayer.reset(null);
    tagsReplayer.reset(null);
  });

  Widget createTestWidget({AddLinkViewArguments? arguments}) {
    return MaterialApp(
      routes: {
        'userInstance/newEdit': (context) => const Scaffold(body: Text('New User Instance Mock')),
      },
      home: Scaffold(body: AddLinkView(arguments: arguments)),
    );
  }

  group('AddLinkView', () {
    testWidgets('validation failure', (WidgetTester tester) async {
      userInstanceValueReplayer.publish([
        UserInstance(
          id: "1",
          server: "https://example.com",
          apiToken: "token123",
        )
      ]);
      await setDefaultUserInstance("1");

      collectionsReplayer.publish([], currentKey: "1");
      tagsReplayer.publish([], currentKey: "1");

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Validation errors'), findsOneWidget);
    });

    testWidgets('instance A -> B clears collection and tags', (WidgetTester tester) async {
      final instanceA = UserInstance(id: "A", server: "https://a.com", apiToken: "tokA");
      final instanceB = UserInstance(id: "B", server: "https://b.com", apiToken: "tokB");

      userInstanceValueReplayer.publish([instanceA, instanceB]);
      await setDefaultUserInstance("A");

      collectionsReplayer.publish([Collection(id: 1, name: "ColA")], currentKey: "A");
      tagsReplayer.publish([], currentKey: "A");
      collectionsReplayer.publish([Collection(id: 2, name: "ColB")], currentKey: "B");
      tagsReplayer.publish([], currentKey: "B");

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('https://a.com'), findsOneWidget);

      await tester.tap(find.text('https://a.com'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('https://b.com').last);
      await tester.pumpAndSettle();

      expect(find.text('https://b.com'), findsOneWidget);
    });

    testWidgets('preview timeout/failure', (WidgetTester tester) async {
      userInstanceValueReplayer.publish([
        UserInstance(id: "1", server: "https://example.com", apiToken: "token123")
      ]);
      await setDefaultUserInstance("1");

      collectionsReplayer.publish([], currentKey: "1");
      tagsReplayer.publish([], currentKey: "1");

      await tester.pumpWidget(createTestWidget(arguments: AddLinkViewArguments(link: "http://bad.url")));
      await tester.pumpAndSettle();

      expect(find.text('Preview unavailable or failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('duplicate-click prevention', (WidgetTester tester) async {
      userInstanceValueReplayer.publish([
        UserInstance(id: "1", server: "https://example.com", apiToken: "token123")
      ]);
      await setDefaultUserInstance("1");

      collectionsReplayer.publish([Collection(id: 1, name: "ColA")], currentKey: "1");
      tagsReplayer.publish([], currentKey: "1");

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Submit'), findsOneWidget);
    });
  });
}
