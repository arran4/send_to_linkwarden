import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/model/collection.dart';
import 'package:send_to_linkwarden/view/add_collection_view.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'test_helpers.dart';

void main() {
  group('AddCollectionView', () {
    testWidgets(
      'responsive layout prevents RenderFlex overflow on narrow widths for colour Wrap',
      (WidgetTester tester) async {
        setViewportSize(tester, 320, 800);
        await tester.pumpWidget(const MaterialApp(home: AddCollectionView()));
        await tester.pumpAndSettle();

        // Simulate input and keyboard traversal
        final nameField = find.byType(TextFormField).first;
        final descField = find.byType(TextFormField).last;

        await tester.enterText(nameField, 'Test Collection Name');
        await tester.tap(nameField);
        await tester.pumpAndSettle();
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();

        // Assert focus actually moved
        final FocusNode descFocusNode = tester
            .widget<EditableText>(
              find.descendant(
                of: descField,
                matching: find.byType(EditableText),
              ),
            )
            .focusNode;
        expect(descFocusNode.hasFocus, isTrue);

        expect(tester.takeException(), isNull); // Verify no RenderFlex overflow
      },
    );

    testWidgets(
      'multiline description field explicitly preserves newline behavior',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: AddCollectionView()));
        await tester.pumpAndSettle();

        final descField = find.byType(TextFormField).last;
        await tester.enterText(descField, 'First line\nSecond line');
        await tester.tap(descField);
        await tester.pumpAndSettle();

        await tester.testTextInput.receiveAction(TextInputAction.newline);
        await tester.pumpAndSettle();

        final EditableText descEditableText = tester.widget<EditableText>(
          find.descendant(of: descField, matching: find.byType(EditableText)),
        );
        expect(descEditableText.controller.text, 'First line\nSecond line');

        // Assert that we are still on the form and the form did not submit.
        expect(find.byType(AddCollectionView), findsOneWidget);
      },
    );

    testWidgets(
      'Responsive Layout at 1200px constrains form width to max 600',
      (WidgetTester tester) async {
        setViewportSize(tester, 1200, 800);
        await tester.pumpWidget(const MaterialApp(home: AddCollectionView()));
        await tester.pumpAndSettle();

        final cardRect = tester.getRect(find.byType(Card).first);
        expect(cardRect.width, lessThanOrEqualTo(600));
      },
    );

    testWidgets('validation prevents saving empty name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AddCollectionView()));

      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert validation error
      expect(find.text('Please enter a value'), findsOneWidget);
      expect(find.text('Validation errors'), findsOneWidget); // Snackbar
    });

    testWidgets('color picker cancel preserves original color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AddCollectionView()));

      await tester.pumpAndSettle();

      // Find initial color text
      final initialColorHex = '#008080';
      expect(find.text(initialColorHex), findsOneWidget);

      // Tap Change to open color picker
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      expect(find.byType(ColorPicker), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Picker is gone
      expect(find.byType(ColorPicker), findsNothing);

      // Color is unchanged
      expect(find.text(initialColorHex), findsOneWidget);
    });

    testWidgets('color picker apply updates color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AddCollectionView()));

      await tester.pumpAndSettle();

      // Tap Change to open color picker
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      expect(find.byType(ColorPicker), findsOneWidget);

      final picker = tester.widget<ColorPicker>(find.byType(ColorPicker));
      picker.onColorChanged(const Color(0xffff0000));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.byType(ColorPicker), findsNothing);
      expect(find.text('#FF0000'), findsOneWidget);
    });

    testWidgets('successful save returns populated Collection', (
      WidgetTester tester,
    ) async {
      Collection? resultCollection;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddCollectionView(),
                    ),
                  );
                  if (result is Collection) {
                    resultCollection = result;
                  }
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Fill in details
      await tester.enterText(
        find.byType(TextFormField).first,
        'Test Collection',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'Test Description',
      );
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      final picker = tester.widget<ColorPicker>(find.byType(ColorPicker));
      picker.onColorChanged(const Color(0xffff0000));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(resultCollection, isNotNull);
      expect(resultCollection!.name, 'Test Collection');
      expect(resultCollection!.description, 'Test Description');
      expect(resultCollection!.color, '#ff0000');
    });
  });
}
