import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/model/tag.dart';
import 'package:send_to_linkwarden/view/select_tags_view.dart';

void main() {
  group('SelectTagsView - UI Tests', () {
    testWidgets('substring match filtering shows create option', (
      WidgetTester tester,
    ) async {
      final List<Tag> allTags = [Tag(name: 'foobar')];

      await tester.pumpWidget(
        MaterialApp(
          home: SelectTagsView(
            arguments: SelectTagsViewArguments(allTags: allTags),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter a substring
      await tester.enterText(find.byType(TextField), 'foo');
      await tester.pumpAndSettle();

      // Ensure 'foobar' is still visible (substring filter match, not looking at textfield)
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('foobar'),
        ),
        findsOneWidget,
      );

      // Ensure 'Create tag 'foo'' is presented
      expect(find.text("Create tag 'foo'"), findsOneWidget);
    });

    testWidgets('exact match prevents duplicates and selects existing tag', (
      WidgetTester tester,
    ) async {
      final List<Tag> allTags = [Tag(name: 'foobar')];

      await tester.pumpWidget(
        MaterialApp(
          home: SelectTagsView(
            arguments: SelectTagsViewArguments(allTags: allTags),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter an exact match
      await tester.enterText(find.byType(TextField), 'foobar');
      await tester.pumpAndSettle();

      // Ensure 'foobar' is visible in the list
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('foobar'),
        ),
        findsOneWidget,
      );

      // Ensure 'Create tag 'foobar'' is NOT presented
      expect(find.text("Create tag 'foobar'"), findsNothing);

      // Submit the text (simulate pressing Enter/Add)
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify the existing tag is checked
      final Checkbox checkbox = tester.widget(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('whitespace input prevents creation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectTagsView(arguments: SelectTagsViewArguments(allTags: [])),
        ),
      );

      await tester.pumpAndSettle();

      // Enter whitespace
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();

      // Ensure 'Create tag ...' is not offered for empty strings
      expect(find.text("Create tag ''"), findsNothing);
      expect(find.text("Create tag '   '"), findsNothing);

      // Submit the text
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // List should still say no tags found
      expect(find.text('No tags found. Create one below.'), findsOneWidget);
    });

    testWidgets(
      'case behavior selects existing tag without creating duplicate',
      (WidgetTester tester) async {
        final List<Tag> allTags = [Tag(name: 'foo')];

        await tester.pumpWidget(
          MaterialApp(
            home: SelectTagsView(
              arguments: SelectTagsViewArguments(allTags: allTags),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter case variant
        await tester.enterText(find.byType(TextField), 'Foo');
        await tester.pumpAndSettle();

        // Ensure creation of 'Foo' is not offered because 'foo' exists
        expect(find.text("Create tag 'Foo'"), findsNothing);

        // Submit
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Original 'foo' should be checked
        final Checkbox checkbox = tester.widget(find.byType(Checkbox));
        expect(checkbox.value, isTrue);
      },
    );

    testWidgets('creation action creates and selects tag', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectTagsView(arguments: SelectTagsViewArguments(allTags: [])),
        ),
      );

      await tester.pumpAndSettle();

      // Enter new tag
      await tester.enterText(find.byType(TextField), 'newtag');
      await tester.pumpAndSettle();

      // Tap create
      await tester.tap(find.text("Create tag 'newtag'"));
      await tester.pumpAndSettle();

      // Now 'newtag' exists and is checked
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('newtag'),
        ),
        findsOneWidget,
      );
      final Checkbox checkbox = tester.widget(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('deselection action removes tag', (WidgetTester tester) async {
      final List<Tag> allTags = [Tag(name: 'existing')];

      await tester.pumpWidget(
        MaterialApp(
          home: SelectTagsView(
            arguments: SelectTagsViewArguments(
              allTags: allTags,
              selectedTags: ['existing'],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially checked
      Checkbox checkbox = tester.widget(find.byType(Checkbox));
      expect(checkbox.value, isTrue);

      // Tap to deselect
      await tester.tap(find.text('existing'));
      await tester.pumpAndSettle();

      // Now unchecked
      checkbox = tester.widget(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('no results empty state is distinct from no tags', (
      WidgetTester tester,
    ) async {
      final List<Tag> allTags = [Tag(name: 'existing')];

      await tester.pumpWidget(
        MaterialApp(
          home: SelectTagsView(
            arguments: SelectTagsViewArguments(allTags: allTags),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search that matches nothing
      await tester.enterText(find.byType(TextField), 'nomatch');
      await tester.pumpAndSettle();

      // Should show no match text
      expect(find.text("No tags match your search."), findsOneWidget);
    });

    testWidgets('large tag set scales and scrolls natively', (
      WidgetTester tester,
    ) async {
      // 200 tags
      final List<Tag> allTags = List.generate(200, (i) => Tag(name: 'tag_$i'));

      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: SelectTagsView(
            arguments: SelectTagsViewArguments(allTags: allTags),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('tag_0'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('tag_0'), findsNothing);
      // Reset view
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('preselected tags normalize to canonical casing', (
      WidgetTester tester,
    ) async {
      final List<Tag> allTags = [Tag(name: 'CanonicalCase')];

      await tester.pumpWidget(
        MaterialApp(
          home: SelectTagsView(
            arguments: SelectTagsViewArguments(
              allTags: allTags,
              selectedTags: ['canonicalcase'],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The checkbox next to the canonical tag should be checked
      expect(find.text('CanonicalCase'), findsOneWidget);
      final Checkbox checkbox = tester.widget(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });
  });
}
