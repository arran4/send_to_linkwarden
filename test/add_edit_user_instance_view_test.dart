import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/view/add_edit_user_instance_view.dart';

void main() {
  Widget createWidgetUnderTest() {
    return MaterialApp(home: Scaffold(body: const AddEditUserInstanceView()));
  }

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

    testWidgets('Does not show HTTP warning for localhost', (
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
        findsNothing,
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

        await tester.enterText(urlField, '   ');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Because there are multiple fields that show "Please enter a value" (url, token, etc),
        // we check for at least one.
        expect(find.text('Please enter a value'), findsWidgets);

        await tester.enterText(urlField, 'https://');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Not a valid URL'), findsWidgets);
      },
    );
  });
}

// Wait, I need to setup an HTTP Mock for this. Let's use `HttpOverrides` or mock `http.Client`.
