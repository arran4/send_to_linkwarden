import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/view/add_edit_user_instance_view.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';

import 'test_helpers.dart';

void main() {
  Widget createWidgetUnderTest({UserInstance? instance}) {
    return MaterialApp(
      home: Scaffold(
        body: AddEditUserInstanceView(
          arguments: AddEditUserInstanceViewArguments(userInstance: instance),
        ),
      ),
    );
  }

  group('AddEditUserInstanceView - Responsive and Layout', () {
    testWidgets(
      'Responsive Layout at 320px handles long content and keyboard actions without RenderFlex overflow',
      (WidgetTester tester) async {
        setViewportSize(tester, 320, 800);
        final editingInstance = UserInstance(
          id: 'instA',
          server:
              'http://very-long-linkwarden-server-url-that-exceeds-screen-width.com',
          apiToken: 'tokenA',
        );
        userInstanceValueReplayer.publish([editingInstance]);
        await tester.pumpWidget(
          createWidgetUnderTest(instance: editingInstance),
        );
        await tester.pumpAndSettle();

        final urlField = find.byKey(
          AddEditUserInstanceView.instanceUrlFieldKey,
        );
        await tester.enterText(
          urlField,
          'http://verylongurlthatexceedsthescreenwidth.com/a/b/c/d/e',
        );
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull); // Verify no RenderFlex overflow

        // Verify tooltips
        expect(find.byTooltip('Delete instance'), findsOneWidget);
        expect(find.byTooltip('Show/Hide API token'), findsOneWidget);

      },
    );

    testWidgets('Focus transitions correctly across Username/Password auth', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Switch to Username/Password method
      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Username/Password').last);
      await tester.pumpAndSettle();

      final usernameField = find.byKey(AddEditUserInstanceView.usernameFieldKey);
      final passwordField = find.byKey(AddEditUserInstanceView.passwordFieldKey);

      await tester.enterText(usernameField, 'test@example.com');
      await tester.tap(usernameField);
      await tester.pumpAndSettle();

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      final FocusNode pwdFocusNode = FocusScope.of(tester.element(passwordField)).focusedChild!;
      expect(pwdFocusNode.hasFocus, isTrue);
    });

    testWidgets('Done/activation works for validation-only path without hitting network', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final tokenField = find.byType(TextFormField).last;

      await tester.tap(tokenField);
      await tester.pumpAndSettle();

      // Trigger submission with invalid URL setup to avoid network calls
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Please correct the validation errors before saving.'), findsOneWidget);
    });
  });

  group('AddEditUserInstanceView - Validation and Normalization', () {
    testWidgets('Shows HTTP warning when using http://', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final urlField = find.ancestor(
        of: find.text('URL'),
        matching: find.byType(TextFormField),
      );

      await tester.enterText(urlField, 'http://example.com');
      await tester.pumpAndSettle();

      expect(
        find.text('Warning: Credentials will be sent over insecure HTTP.'),
        findsOneWidget,
      );
    });

    testWidgets('Shows HTTP warning for localhost', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final urlField = find.ancestor(
        of: find.text('URL'),
        matching: find.byType(TextFormField),
      );

      await tester.enterText(urlField, 'http://localhost:3000');
      await tester.pumpAndSettle();

      expect(
        find.text('Warning: Credentials will be sent over insecure HTTP.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'URL field validation normalizes implicitly and shows error on empty host',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final urlField = find.ancestor(
          of: find.text('URL'),
          matching: find.byType(TextFormField),
        );

        final saveButton = find.text('Save');
        await tester.ensureVisible(saveButton);
        await tester.enterText(urlField, '   ');
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(find.text('Please enter a value'), findsWidgets);

        await tester.enterText(urlField, 'https://example.com///');
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(find.text('Not a valid URL'), findsNothing);

        await tester.enterText(urlField, 'https://');
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        expect(find.text('Not a valid URL'), findsWidgets);

        await tester.enterText(urlField, 'http://a/');
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(find.text('Not a valid URL'), findsNothing);

        await tester.enterText(urlField, 'https://example.com///');
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        expect(find.text('Not a valid URL'), findsNothing);
      },
    );
  });
}
