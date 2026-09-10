import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/view/add_edit_user_instance_view.dart';

void main() {
  group('AddEditUserInstanceView - UI Interactions', () {
    testWidgets('Toggles password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const AddEditUserInstanceView())),
      );
      await tester.pumpAndSettle();

      // Switch to Username/Password method
      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Username/Password').last);
      await tester.pumpAndSettle();

      final passwordFieldFinder = find.byKey(
        AddEditUserInstanceView.passwordFieldKey,
      );
      expect(passwordFieldFinder, findsOneWidget);
      TextField textField = tester.widget(
        find.descendant(
          of: passwordFieldFinder,
          matching: find.byType(TextField),
        ),
      );
      expect(textField.obscureText, isTrue);

      final visibilityIcon = find.descendant(
        of: passwordFieldFinder,
        matching: find.byIcon(Icons.visibility),
      );
      expect(visibilityIcon, findsOneWidget);

      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      textField = tester.widget(
        find.descendant(
          of: passwordFieldFinder,
          matching: find.byType(TextField),
        ),
      );
      expect(textField.obscureText, isFalse);
    });

    testWidgets('Toggles API token visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const AddEditUserInstanceView())),
      );
      await tester.pumpAndSettle();

      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('API token').last);
      await tester.pumpAndSettle();

      final apiTokenFieldFinder = find.byKey(
        AddEditUserInstanceView.apiTokenFieldKey,
      );
      expect(apiTokenFieldFinder, findsOneWidget);
      TextField textField = tester.widget(
        find.descendant(
          of: apiTokenFieldFinder,
          matching: find.byType(TextField),
        ),
      );
      expect(textField.obscureText, isTrue);

      final visibilityIcon = find.descendant(
        of: apiTokenFieldFinder,
        matching: find.byIcon(Icons.visibility),
      );
      expect(visibilityIcon, findsOneWidget);

      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      textField = tester.widget(
        find.descendant(
          of: apiTokenFieldFinder,
          matching: find.byType(TextField),
        ),
      );
      expect(textField.obscureText, isFalse);
    });
  });
}
