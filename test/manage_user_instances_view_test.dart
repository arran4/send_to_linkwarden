import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';
import 'package:send_to_linkwarden/view/manage_user_instances_view.dart';
import 'package:send_to_linkwarden/state/default_user_instance.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    userInstanceValueReplayer.publish([]);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      routes: {
        'userInstance/newEdit': (context) =>
            const Scaffold(body: Text('New Edit View')),
      },
      home: const Scaffold(body: ManageUserInstancesView()),
    );
  }

  testWidgets('delete instance flow with confirmation and safe messaging', (
    WidgetTester tester,
  ) async {
    final instance = UserInstance(
      id: '1',
      server: 'https://linkwarden.example.com',
      user: 'testuser1',
    );
    userInstanceValueReplayer.publish([instance]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    final deleteButton = find.descendant(
      of: find.byKey(const ValueKey('1')),
      matching: find.widgetWithIcon(IconButton, Icons.delete),
    );
    expect(deleteButton, findsOneWidget);

    await tester.tap(deleteButton);
    await tester.pump();

    expect(find.text('Delete Instance'), findsOneWidget);
    expect(
      find.text(
        'Are you sure you want to delete https://linkwarden.example.com?',
      ),
      findsOneWidget,
    );

    final cancelButton = find.text('Cancel');
    expect(cancelButton, findsOneWidget);

    await tester.tap(cancelButton);
    await tester.pump();

    expect(find.text('Delete Instance'), findsNothing);

    await tester.tap(deleteButton);
    await tester.pump();

    final confirmDeleteButton = find.text('Delete');
    expect(confirmDeleteButton, findsOneWidget);

    await tester.tap(confirmDeleteButton);
    await tester.pump();

    expect(find.text('Delete Instance'), findsNothing);
    expect(find.text('Instance deleted successfully.'), findsOneWidget);
  });

  testWidgets('edit navigation receives correct instance', (
    WidgetTester tester,
  ) async {
    final instance = UserInstance(
      id: '1',
      server: 'https://linkwarden.example.com',
      user: 'testuser1',
    );
    userInstanceValueReplayer.publish([instance]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    final editButton = find.descendant(
      of: find.byKey(const ValueKey('1')),
      matching: find.widgetWithIcon(IconButton, Icons.edit),
    );
    expect(editButton, findsOneWidget);

    await tester.tap(editButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('New Edit View'), findsOneWidget);
  });

  test(
    'reorder upward and downward preserves default-instance invariant',
    () async {
      final instance1 = UserInstance(
        id: '1',
        server: 'https://1.com',
        user: 'user1',
      );
      final instance2 = UserInstance(
        id: '2',
        server: 'https://2.com',
        user: 'user2',
      );
      final instance3 = UserInstance(
        id: '3',
        server: 'https://3.com',
        user: 'user3',
      );

      upsertUserInstance(instance1);
      await Future.delayed(const Duration(milliseconds: 10));
      upsertUserInstance(instance2);
      await Future.delayed(const Duration(milliseconds: 10));
      upsertUserInstance(instance3);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(await loadDefaultUserInstance(), '1');

      reorderUserInstances(2, 0);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(await loadDefaultUserInstance(), '3');

      reorderUserInstances(0, 3);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(await loadDefaultUserInstance(), '1');
    },
  );
  testWidgets(
    'long lists at narrow and desktop widths scroll without overflow',
    (WidgetTester tester) async {
      final instances = List.generate(
        20,
        (index) => UserInstance(
          id: '$index',
          server: 'https://$index.com',
          user: 'user$index',
        ),
      );
      userInstanceValueReplayer.publish(instances);

      // Test narrow mobile width
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(tester.takeException(), isNull);

      // Test wide desktop width
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}
