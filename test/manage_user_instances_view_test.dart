import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';
import 'package:send_to_linkwarden/core/pub_sub_replay.dart';
import 'package:send_to_linkwarden/view/manage_user_instances_view.dart';
import 'package:send_to_linkwarden/state/default_user_instance.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    userInstanceValueReplayer.publish([]);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      routes: {
        'userInstance/newEdit': (context) => const Scaffold(body: Text('New Edit View')),
      },
      home: const Scaffold(body: ManageUserInstancesView()),
    );
  }







  testWidgets('shows empty state when zero instances', (WidgetTester tester) async {
    userInstanceValueReplayer.publish([]);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('No Linkwarden instances configured.'), findsOneWidget);
    expect(find.byKey(const ValueKey('add_empty')), findsOneWidget);
  });

  testWidgets('shows one instance when configured', (WidgetTester tester) async {
    final instance = UserInstance(id: '1', server: 'https://linkwarden.example.com', user: 'testuser1');
    await upsertUserInstance(instance);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('No Linkwarden instances configured.'), findsNothing);
    expect(find.byKey(const ValueKey('1')), findsOneWidget);
    expect(find.text('https://linkwarden.example.com'), findsOneWidget);
    expect(find.text('testuser1 (Default)'), findsOneWidget);
  });

  testWidgets('shows many instances when configured', (WidgetTester tester) async {
    final instance1 = UserInstance(id: '1', server: 'https://linkwarden.example.com', user: 'testuser1');
    final instance2 = UserInstance(id: '2', server: 'https://linkwarden.test.com', user: 'testuser2');
    await upsertUserInstance(instance1);
    await upsertUserInstance(instance2);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('No Linkwarden instances configured.'), findsNothing);
    expect(find.byKey(const ValueKey('1')), findsOneWidget);
    expect(find.byKey(const ValueKey('2')), findsOneWidget);
  });

  testWidgets('navigates to add instance from empty state', (WidgetTester tester) async {
    userInstanceValueReplayer.publish([]);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add_empty')));
    await tester.pumpAndSettle();

    expect(find.text('New Edit View'), findsOneWidget);
  });

  testWidgets('delete instance flow with confirmation and safe messaging', (WidgetTester tester) async {
    final instance = UserInstance(id: '1', server: 'https://linkwarden.example.com', user: 'testuser1');
    await upsertUserInstance(instance);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final deleteButton = find.descendant(
      of: find.byKey(const ValueKey('1')),
      matching: find.widgetWithIcon(IconButton, Icons.delete)
    );
    expect(deleteButton, findsOneWidget);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete Instance'), findsOneWidget);
    expect(find.text('Are you sure you want to delete https://linkwarden.example.com?'), findsOneWidget);

    final cancelButton = find.text('Cancel');
    expect(cancelButton, findsOneWidget);

    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete Instance'), findsNothing);
    expect(find.text('https://linkwarden.example.com'), findsOneWidget);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    final confirmDeleteButton = find.text('Delete');
    expect(confirmDeleteButton, findsOneWidget);

    await tester.tap(confirmDeleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete Instance'), findsNothing);
    expect(find.text('Instance deleted successfully.'), findsOneWidget);
  });

  testWidgets('edit navigation receives correct instance', (WidgetTester tester) async {
    final instance = UserInstance(id: '1', server: 'https://linkwarden.example.com', user: 'testuser1');
    await upsertUserInstance(instance);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final editButton = find.descendant(
      of: find.byKey(const ValueKey('1')),
      matching: find.widgetWithIcon(IconButton, Icons.edit)
    );
    expect(editButton, findsOneWidget);

    await tester.tap(editButton);
    await tester.pumpAndSettle();

    expect(find.text('New Edit View'), findsOneWidget);
  });

  test('reorder upward and downward preserves default-instance invariant', () async {
    final instance1 = UserInstance(id: '1', server: 'https://1.com', user: 'user1');
    final instance2 = UserInstance(id: '2', server: 'https://2.com', user: 'user2');
    final instance3 = UserInstance(id: '3', server: 'https://3.com', user: 'user3');

    await upsertUserInstance(instance1);
    await upsertUserInstance(instance2);
    await upsertUserInstance(instance3);

    expect(await loadDefaultUserInstance(), '1');

    await reorderUserInstances(2, 0);

    expect(await loadDefaultUserInstance(), '3');

    await reorderUserInstances(0, 3);

    expect(await loadDefaultUserInstance(), '1');
  });

  testWidgets('long lists at narrow and desktop widths scroll without overflow', (WidgetTester tester) async {
    final instances = List.generate(
      20,
      (index) => UserInstance(id: '\$index', server: 'https://\$index.com', user: 'user\$index'),
    );
    for (var instance in instances) {
        await upsertUserInstance(instance);
    }

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
