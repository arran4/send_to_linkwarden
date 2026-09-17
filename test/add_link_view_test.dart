import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/model/collection.dart';
import 'package:send_to_linkwarden/model/link.dart';
import 'package:send_to_linkwarden/model/tag.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/state/collections_replayer.dart';
import 'package:send_to_linkwarden/state/tags_replayer.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';
import 'package:send_to_linkwarden/view/add_link_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'defaultUserInstance': 'instA'});
    userInstanceValueReplayer.publish([
      UserInstance(id: 'instA', server: 'http://a.com', apiToken: 'tokenA'),
      UserInstance(id: 'instB', server: 'http://b.com', apiToken: 'tokenB'),
    ]);
    collectionsReplayer.publish([
      Collection(id: 1, name: 'ColA'),
    ], currentKey: 'instA');
    collectionsReplayer.publish([
      Collection(id: 2, name: 'ColB'),
    ], currentKey: 'instB');
    tagsReplayer.publish([Tag(id: 1, name: 'TagA')], currentKey: 'instA');
    tagsReplayer.publish([Tag(id: 2, name: 'TagB')], currentKey: 'instB');
  });

  Widget buildTestWidget({
    Future<Link?> Function(String token, String baseUrl, Link link)?
    postLinkOverride,
    Future<Map<String, String?>> Function(String url)? fetchPreviewOverride,
    Future<Collection?> Function(
      String token,
      String baseUrl,
      Collection collection,
    )?
    createCollectionOverride,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AddLinkView(
          postLinkOverride: postLinkOverride,
          fetchPreviewOverride: fetchPreviewOverride,
          createCollectionOverride: createCollectionOverride,
        ),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == 'tags/select') {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(leading: const BackButton()),
              body: ListTile(
                title: const Text('TagA'),
                onTap: () {
                  Navigator.pop(context, ['TagA']);
                },
              ),
            ),
          );
        }
        if (settings.name == 'collection/new') {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(leading: const BackButton()),
              body: ListTile(
                title: const Text('NewCol'),
                onTap: () {
                  // We simulate creating a collection by passing a Collection back
                  Navigator.pop(context, Collection(id: 3, name: 'NewCol'));
                },
              ),
            ),
          );
        }
        return MaterialPageRoute(builder: (context) => const SizedBox.shrink());
      },
    );
  }

  group('AddLinkView Acceptance Criteria', () {
    testWidgets(
      'Validation failure shows error snackbar and no progress indicator',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(AddLinkView.submitButtonKey));
        await tester.pump();

        expect(find.text('Validation errors'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets('Duplicate submission prevention', (WidgetTester tester) async {
      int calls = 0;
      final completer = Completer<Link?>();

      await tester.pumpWidget(
        buildTestWidget(
          postLinkOverride: (token, baseUrl, link) {
            calls++;
            return completer.future;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid fields
      await tester.enterText(
        find.byType(TextFormField).first,
        'https://example.com',
      );
      await tester.tap(find.byKey(AddLinkView.collectionDropdownKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ColA').last);
      await tester.pumpAndSettle();

      // Tap submit first time
      await tester.tap(find.byKey(AddLinkView.submitButtonKey));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 10));

      expect(
        find.descendant(
          of: find.byKey(AddLinkView.submitButtonKey),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(calls, equals(1));

      // The button should be disabled, meaning tap does not trigger again
      await tester.tap(find.byKey(AddLinkView.submitButtonKey));
      await tester.pump();
      expect(calls, equals(1));

      // Resolve
      completer.complete(Link(id: 99));
      await tester.pumpAndSettle();
      expect(calls, equals(1));
    });

    testWidgets('Submit failure preserves draft data', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          postLinkOverride: (token, baseUrl, link) =>
              Future.error(Exception('Network error')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'https://example.com',
      );
      await tester.tap(find.byKey(AddLinkView.collectionDropdownKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ColA').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AddLinkView.submitButtonKey));
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Failed to submit bookmark. Please check your connection and try again.',
        ),
        findsOneWidget,
      );
      // Draft URL is still there
      expect(find.text('https://example.com'), findsOneWidget);
    });

    testWidgets('Submit returning null preserves draft data', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          postLinkOverride: (token, baseUrl, link) => Future.value(null),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'https://example.com',
      );
      await tester.tap(find.byKey(AddLinkView.collectionDropdownKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ColA').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AddLinkView.submitButtonKey));
      await tester.pumpAndSettle();

      // No success message should appear
      expect(find.text('Bookmark saved successfully'), findsNothing);
      // Form should not be reset, draft is preserved
      expect(find.text('https://example.com'), findsOneWidget);
    });

    testWidgets('Successful submit resets form', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          postLinkOverride: (token, baseUrl, link) =>
              Future.value(Link(id: 123)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'https://example.com',
      );
      await tester.tap(find.byKey(AddLinkView.collectionDropdownKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ColA').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AddLinkView.submitButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('Bookmark saved successfully'), findsOneWidget);
      // Form reset -> empty fields and cleared collection
      expect(find.text('https://example.com'), findsNothing);
      expect(find.text('ColA'), findsNothing);
    });

    testWidgets(
      'A->B isolation: clears collection and tags, preserves drafts',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Type draft data
        await tester.enterText(
          find.byType(TextFormField).first,
          'https://draft.com',
        );

        // Select ColA
        await tester.tap(find.byKey(AddLinkView.collectionDropdownKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ColA').last);
        await tester.pumpAndSettle();

        // Select TagA
        await tester.tap(find.byKey(AddLinkView.editTagsButtonKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text('TagA'));
        await tester.pumpAndSettle();

        expect(find.text('ColA'), findsWidgets);
        expect(find.text('TagA'), findsWidgets);

        // Switch to B
        await tester.tap(find.byKey(AddLinkView.instanceDropdownKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text('http://b.com').last);
        await tester.pumpAndSettle();

        // Draft survived
        expect(find.text('https://draft.com'), findsOneWidget);

        // A-scoped data cleared
        expect(find.text('ColA'), findsNothing);
        expect(find.text('TagA'), findsNothing);
      },
    );

    testWidgets(
      'A->New/no instance isolation: clears collection and tags, preserves drafts',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Type draft data
        await tester.enterText(
          find.byType(TextFormField).first,
          'https://draft.com',
        );

        // Select ColA
        await tester.tap(find.byKey(AddLinkView.collectionDropdownKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ColA').last);
        await tester.pumpAndSettle();

        // Select TagA
        await tester.tap(find.byKey(AddLinkView.editTagsButtonKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text('TagA'));
        await tester.pumpAndSettle();
        // The mock route pops automatically when TagA is tapped. No back button needed.

        expect(find.text('ColA'), findsWidgets);
        expect(find.text('TagA'), findsWidgets);

        // Switch to New
        await tester.tap(find.byKey(AddLinkView.instanceDropdownKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text('New').last);
        await tester.pumpAndSettle();

        // Draft survived
        expect(find.text('https://draft.com'), findsOneWidget);

        // ColA and TagA cleared
        expect(find.text('ColA'), findsNothing);
        expect(find.text('TagA'), findsNothing);
      },
    );

    testWidgets('create-collection-then-switch coverage', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          createCollectionOverride: (token, baseUrl, collection) =>
              Future.value(collection),
        ),
      );
      await tester.pumpAndSettle();

      // Tap add collection, mock route pops a Collection obj
      await tester.tap(find.byKey(AddLinkView.addCollectionButtonKey));
      await tester.pumpAndSettle();

      // Mock route tap inside the stub listview
      await tester.tap(find.text('NewCol'));
      await tester.pumpAndSettle();

      // Should be selected visually
      expect(find.text('NewCol'), findsWidgets);

      // Switch to B
      await tester.tap(find.byKey(AddLinkView.instanceDropdownKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('http://b.com').last);
      await tester.pumpAndSettle();

      // Ensure stable switch
      expect(find.text('http://b.com'), findsWidgets);

      // Ensure NewCol is cleared
      expect(find.text('NewCol'), findsNothing);
    });

    testWidgets('Preview timeout degrades gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          fetchPreviewOverride: (url) async {
            throw TimeoutException('Timed out');
          },
        ),
      );
      await tester.pumpAndSettle();

      // Input URL to trigger preview
      await tester.enterText(
        find.byType(TextFormField).first,
        'https://example.com',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Should show loading state initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Should show error state gracefully
      expect(find.text('Preview unavailable'), findsOneWidget);
    });
  });
}
