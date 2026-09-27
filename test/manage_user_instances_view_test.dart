import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/core/pub_sub_replay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:send_to_linkwarden/state/user_instance_replayer.dart';
import 'package:send_to_linkwarden/view/manage_user_instances_view.dart';

import 'package:send_to_linkwarden/view/add_edit_user_instance_view.dart';

void main() {
  setUp(() {
    // Reset test seams
    readSecureStorage = (key) async => null;
    writeSecureStorage = (key, value) async {};
    userInstanceValueReplayer = PubSubReplay(
      onNoLastMessage: loadUserInstances,
    );
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == 'userInstance/newEdit') {
          final args = settings.arguments as AddEditUserInstanceViewArguments?;
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  Text('New Edit View: ${args?.userInstance?.id ?? "null"}'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        UserInstance(
                          id: '99',
                          server: 'https://new.com',
                          user: 'newuser',
                        ),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          );
        }
        return null;
      },
      home: const Scaffold(body: ManageUserInstancesView()),
    );
  }

  testWidgets('safe error messaging when stream errors', (
    WidgetTester tester,
  ) async {
    readSecureStorage = (key) async {
      throw Exception('Simulated Database Failure');
    };

    // trigger onNoLastMessage
    userInstanceValueReplayer = PubSubReplay(
      onNoLastMessage: loadUserInstances,
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(
      find.text('Failed to load instances. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Simulated Database Failure'), findsNothing);
  });

  testWidgets('safe delete failure messaging without mutating view state', (
    WidgetTester tester,
  ) async {
    readSecureStorage = (key) async =>
        '[{"id":"1","server":"https://linkwarden.example.com","user":"testuser1"}]';

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    writeSecureStorage = (key, value) async {
      throw Exception('Storage write failure');
    };

    final deleteButton = find.descendant(
      of: find.byKey(const ValueKey('1')),
      matching: find.widgetWithIcon(IconButton, Icons.delete),
    );
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(find.text('Failed to delete instance.'), findsOneWidget);
    expect(find.text('Storage write failure'), findsNothing);
    expect(find.text('https://linkwarden.example.com'), findsOneWidget);
  });

  testWidgets('safe save failure messaging without unhandled error', (
    WidgetTester tester,
  ) async {
    readSecureStorage = (key) async => '[]';
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add_empty')));
    await tester.pumpAndSettle();

    // Configure write to fail
    writeSecureStorage = (key, value) async {
      throw Exception('Storage write failure');
    };

    // Tap Save button which returns the UserInstance and triggers upsertUserInstance
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Failed to save instance.'), findsWidgets);
    expect(find.text('Storage write failure'), findsNothing);
  });

  testWidgets('shows empty state when zero instances', (
    WidgetTester tester,
  ) async {
    readSecureStorage = (key) async => '[]';
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('No Linkwarden instances configured.'), findsOneWidget);
    expect(find.byKey(const ValueKey('add_empty')), findsOneWidget);
  });

  testWidgets(
    'shows one instance when configured with null server and user fallbacks',
    (WidgetTester tester) async {
      readSecureStorage = (key) async => '[{"id":"1"}]';
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('No Linkwarden instances configured.'), findsNothing);
      expect(find.byKey(const ValueKey('1')), findsOneWidget);
      expect(find.text('Unknown URL'), findsOneWidget);
      expect(find.text('No User (Default)'), findsOneWidget);

      // Check tooltips/semantics
      expect(find.byTooltip('Default instance'), findsOneWidget);
      expect(find.byTooltip('Edit instance'), findsOneWidget);
      expect(find.byTooltip('Delete instance'), findsOneWidget);
      expect(find.byTooltip('Drag to reorder and set default'), findsOneWidget);

      final deleteButton = find.descendant(
        of: find.byKey(const ValueKey('1')),
        matching: find.widgetWithIcon(IconButton, Icons.delete),
      );
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      expect(
        find.text('Are you sure you want to delete this instance?'),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows many instances when configured', (
    WidgetTester tester,
  ) async {
    readSecureStorage = (key) async =>
        '[{"id":"1","server":"https://linkwarden.example.com","user":"testuser1"},{"id":"2","server":"https://linkwarden.test.com","user":"testuser2"}]';
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('No Linkwarden instances configured.'), findsNothing);
    expect(find.byKey(const ValueKey('1')), findsOneWidget);
    expect(find.byKey(const ValueKey('2')), findsOneWidget);

    expect(find.byTooltip('Default instance'), findsOneWidget);
    expect(find.byTooltip('Instance'), findsOneWidget);

    expect(find.text('testuser1 (Default)'), findsOneWidget);
    expect(find.text('testuser2'), findsOneWidget);
  });

  testWidgets('navigates to add instance from empty state', (
    WidgetTester tester,
  ) async {
    readSecureStorage = (key) async => '[]';
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add_empty')));
    await tester.pumpAndSettle();

    expect(find.text('New Edit View: null'), findsOneWidget);
  });

  testWidgets('navigates to add instance from list state', (
    WidgetTester tester,
  ) async {
    readSecureStorage = (key) async =>
        '[{"id":"1","server":"https://linkwarden.example.com","user":"testuser1"}]';
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add')));
    await tester.pumpAndSettle();

    expect(find.text('New Edit View: null'), findsOneWidget);
  });

  testWidgets('delete instance flow with confirmation', (
    WidgetTester tester,
  ) async {
    readSecureStorage = (key) async =>
        '[{"id":"1","server":"https://linkwarden.example.com","user":"testuser1"}]';
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final deleteButton = find.descendant(
      of: find.byKey(const ValueKey('1')),
      matching: find.widgetWithIcon(IconButton, Icons.delete),
    );
    expect(deleteButton, findsOneWidget);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();
  });

  testWidgets('edit navigation receives correct instance arguments', (
    WidgetTester tester,
  ) async {
    readSecureStorage = (key) async =>
        '[{"id":"1","server":"https://linkwarden.example.com","user":"testuser1"}]';
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final editButton = find.descendant(
      of: find.byKey(const ValueKey('1')),
      matching: find.widgetWithIcon(IconButton, Icons.edit),
    );
    expect(editButton, findsOneWidget);

    await tester.tap(editButton);
    await tester.pumpAndSettle();

    expect(find.text('New Edit View: 1'), findsOneWidget);
  });

  testWidgets(
    'long lists at narrow and desktop widths scroll without overflow',
    (WidgetTester tester) async {
      String generateInstancesJson() {
        String json = '[';
        for (int i = 0; i < 20; i++) {
          json += '{"id":"$i","server":"https://$i.com","user":"user$i"}';
          if (i < 19) json += ',';
        }
        json += ']';
        return json;
      }

      readSecureStorage = (key) async => generateInstancesJson();

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final lastItemText = find.text('https://19.com');
      expect(lastItemText, findsNothing);

      await tester.scrollUntilVisible(
        lastItemText,
        500,
        scrollable: find.descendant(
          of: find.byType(ReorderableListView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();

      expect(lastItemText, findsOneWidget);

      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
