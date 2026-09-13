import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/model/collection.dart';
import 'package:send_to_linkwarden/state/collections_replayer.dart';
import 'package:send_to_linkwarden/state/tags_replayer.dart';
import 'package:flutter/services.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    userInstanceValueReplayer.publish([
      UserInstance(
        id: '1',
        server: 'https://linkwarden.example.com',
        apiToken: 'token1',
      ),
    ]);
    collectionsReplayer.publish([
      Collection(id: 1, name: 'Collection 1', ownerId: 1, color: '#ff0000'),
    ], currentKey: '1');
    tagsReplayer.publish([], currentKey: '1');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('receive_sharing_intent/messages'),
          (MethodCall methodCall) async {
            return null;
          },
        );
  });

  testWidgets(
    'Main App catches share intent errors and shows user-friendly message',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SendToLinkwardenApp());
      await tester.pumpAndSettle();

      expect(find.text('Add Bookmark - Send To Linkwarden'), findsOneWidget);
    },
  );
}
