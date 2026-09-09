import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:send_to_linkwarden/view/add_edit_user_instance_view.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';

void main() {
  // Navigation wrapper for capturing UserInstance pop
  UserInstance? savedInstance;

  Widget createWidgetWithNavigation(UserInstance? initial) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                child: const Text('Open Form'),
                onPressed: () async {
                  savedInstance = await Navigator.push<UserInstance>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditUserInstanceView(
                        arguments: AddEditUserInstanceViewArguments(
                          userInstance: initial,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  group('AddEditUserInstanceView - Network validation flows', () {
    setUp(() {
      savedInstance = null;
    });

    EditableText editableFor(WidgetTester tester, Key key) {
      return tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(EditableText),
        ),
      );
    }

    testWidgets('API token verification success', (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/collections');
        expect(request.headers['authorization'], 'Bearer valid_token');
        return http.Response('{"response": []}', 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(createWidgetWithNavigation(null));
        await tester.pumpAndSettle();

        // Tap to open the form
        await tester.tap(find.text('Open Form'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(AddEditUserInstanceView.instanceUrlFieldKey),
          findsOneWidget,
        );

        // Switch to API token method explicitly if not rendered by default in test
        final dropdown = find.byType(DropdownButtonFormField<String>);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('API token').last);
        await tester.pumpAndSettle();

        expect(
          find.byKey(AddEditUserInstanceView.apiTokenFieldKey),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(AddEditUserInstanceView.instanceUrlFieldKey),
          'https://example.com',
        );
        await tester.pump();

        await tester.enterText(
          find.byKey(AddEditUserInstanceView.apiTokenFieldKey),
          'valid_token',
        );
        await tester.pump();

        // Assert text is in controller
        expect(
          editableFor(
            tester,
            AddEditUserInstanceView.instanceUrlFieldKey,
          ).controller.text,
          'https://example.com',
        );
        expect(
          editableFor(
            tester,
            AddEditUserInstanceView.apiTokenFieldKey,
          ).controller.text,
          'valid_token',
        );

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Assert we are back to the home page (no AddEditUserInstanceView visible)
        expect(find.byType(AddEditUserInstanceView), findsNothing);
        expect(savedInstance, isNotNull);
        expect(savedInstance!.server, 'https://example.com');
        expect(savedInstance!.apiToken, 'valid_token');
        expect(savedInstance!.password, isNull);
      }, () => mockClient);
    });

    testWidgets(
      'Username/Password login success clears password and retains API token',
      (WidgetTester tester) async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/session');
          return http.Response(
            '{"response": {"token": "generated_session_token"}}',
            200,
          );
        });

        await http.runWithClient(() async {
          final initialInstance = UserInstance();
          await tester.pumpWidget(createWidgetWithNavigation(initialInstance));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Open Form'));
          await tester.pumpAndSettle();

          await tester.enterText(
            find.byKey(AddEditUserInstanceView.instanceUrlFieldKey),
            'https://example.com',
          );
          await tester.pump();

          // Switch to Username/Password method
          final dropdown = find.byType(DropdownButtonFormField<String>);
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Username/Password').last);
          await tester.pumpAndSettle();

          expect(
            find.byKey(AddEditUserInstanceView.usernameFieldKey),
            findsOneWidget,
          );
          expect(
            find.byKey(AddEditUserInstanceView.passwordFieldKey),
            findsOneWidget,
          );

          await tester.enterText(
            find.byKey(AddEditUserInstanceView.usernameFieldKey),
            'test@example.com',
          );
          await tester.pump();

          await tester.enterText(
            find.byKey(AddEditUserInstanceView.passwordFieldKey),
            'my_password',
          );
          await tester.pump();

          // Assert text is in controller
          expect(
            editableFor(
              tester,
              AddEditUserInstanceView.instanceUrlFieldKey,
            ).controller.text,
            'https://example.com',
          );
          expect(
            editableFor(
              tester,
              AddEditUserInstanceView.usernameFieldKey,
            ).controller.text,
            'test@example.com',
          );
          expect(
            editableFor(
              tester,
              AddEditUserInstanceView.passwordFieldKey,
            ).controller.text,
            'my_password',
          );

          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();

          expect(find.byType(AddEditUserInstanceView), findsNothing);

          // Check instance mutation
          expect(savedInstance, isNotNull);
          expect(savedInstance!.password, isNull);
          expect(savedInstance!.apiToken, 'generated_session_token');
          expect(savedInstance!.user, 'test@example.com');
        }, () => mockClient);
      },
    );
  });
}
