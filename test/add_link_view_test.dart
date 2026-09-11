import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/view/add_link_view.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/model/collection.dart';
import 'package:send_to_linkwarden/model/tag.dart';
import 'package:send_to_linkwarden/model/link.dart';
import 'package:send_to_linkwarden/core/individual_keyed_pub_sub_replay.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:send_to_linkwarden/core/pub_sub_replay.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  late IndividualKeyedPubSubReplay<String?, List<Collection>?>
  mockCollectionsReplayer;
  late IndividualKeyedPubSubReplay<String?, List<Tag>?> mockTagsReplayer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    mockCollectionsReplayer =
        IndividualKeyedPubSubReplay<String?, List<Collection>?>(
          onNoLastMessage: (queue, currentKey) {
            queue.publish([], currentKey: currentKey);
          },
        );
    mockTagsReplayer = IndividualKeyedPubSubReplay<String?, List<Tag>?>(
      onNoLastMessage: (queue, currentKey) {
        queue.publish([], currentKey: currentKey);
      },
    );

    userInstanceValueReplayer = PubSubReplay<List<UserInstance>>(
      onNoLastMessage: (queue) {
        queue.publish([]);
      },
    );
  });

  testWidgets('validation failure preserves draft URL', (
    WidgetTester tester,
  ) async {
    final ui = UserInstance(
      id: '1',
      server: 'https://test.com',
      apiToken: 'token',
    );
    userInstanceValueReplayer.publish([ui]);

    await tester.pumpWidget(
      buildTestableWidget(
        AddLinkView(
          loadDefaultUserInstanceOverride: () async => ui.id,
          collectionsReplayerOverride: mockCollectionsReplayer,
          tagsReplayerOverride: mockTagsReplayer,
          fetchPreviewOverride: (url) async => {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final urlField = find.widgetWithText(TextFormField, "Link").first;
    await tester.enterText(urlField, 'not-a-valid-url');
    await tester.pump();

    final submitButton = find.widgetWithText(FilledButton, 'Submit');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton, warnIfMissed: false);
    await tester.pump();

    expect(find.text('not-a-valid-url'), findsOneWidget);
    expect(find.text('Must be http or https'), findsOneWidget);
  });

  testWidgets('submit in-flight state uses completer', (
    WidgetTester tester,
  ) async {
    final completer = Completer<Link?>();
    final ui = UserInstance(
      id: '1',
      server: 'https://test.com',
      apiToken: 'token',
    );
    userInstanceValueReplayer.publish([ui]);

    await tester.pumpWidget(
      buildTestableWidget(
        AddLinkView(
          loadDefaultUserInstanceOverride: () async => ui.id,
          collectionsReplayerOverride: mockCollectionsReplayer,
          tagsReplayerOverride: mockTagsReplayer,
          fetchPreviewOverride: (url) async => {},
          postLinkOverride: (token, baseUrl, link) => completer.future,
        ),
      ),
    );
    await tester.pumpAndSettle();

    mockCollectionsReplayer.publish([
      Collection(id: 1, name: "Col A", ownerId: 1),
    ], currentKey: ui.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Collection>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Col A').last);
    await tester.pumpAndSettle();

    final urlField = find.widgetWithText(TextFormField, "Link").first;
    await tester.enterText(urlField, 'https://example.com');
    await tester.pump();

    final submitButton = find.widgetWithText(FilledButton, 'Submit');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton, warnIfMissed: false);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    completer.complete(null);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('duplicate-submit prevention', (WidgetTester tester) async {
    final completer = Completer<Link?>();
    final ui = UserInstance(
      id: '1',
      server: 'https://test.com',
      apiToken: 'token',
    );
    userInstanceValueReplayer.publish([ui]);

    await tester.pumpWidget(
      buildTestableWidget(
        AddLinkView(
          loadDefaultUserInstanceOverride: () async => ui.id,
          collectionsReplayerOverride: mockCollectionsReplayer,
          tagsReplayerOverride: mockTagsReplayer,
          fetchPreviewOverride: (url) async => {},
          postLinkOverride: (token, baseUrl, link) => completer.future,
        ),
      ),
    );
    await tester.pumpAndSettle();

    mockCollectionsReplayer.publish([
      Collection(id: 1, name: "Col A", ownerId: 1),
    ], currentKey: ui.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Collection>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Col A').last);
    await tester.pumpAndSettle();

    final urlField = find.widgetWithText(TextFormField, "Link").first;
    await tester.enterText(urlField, 'https://example.com');
    await tester.pump();

    final submitButton = find.widgetWithText(FilledButton, 'Submit');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton, warnIfMissed: false);
    await tester.pump();

    final filledButtonList = tester
        .widgetList<FilledButton>(find.byType(FilledButton))
        .toList();
    for (var filledButton in filledButtonList) {
      if (filledButton.child is Text &&
          (filledButton.child as Text).data == 'Submit') {
        expect(filledButton.onPressed, isNull);
      }
    }
    completer.complete(null);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('submit failure preserving drafts', (WidgetTester tester) async {
    final ui = UserInstance(
      id: '1',
      server: 'https://test.com',
      apiToken: 'token',
    );
    userInstanceValueReplayer.publish([ui]);

    await tester.pumpWidget(
      buildTestableWidget(
        AddLinkView(
          loadDefaultUserInstanceOverride: () async => ui.id,
          collectionsReplayerOverride: mockCollectionsReplayer,
          tagsReplayerOverride: mockTagsReplayer,
          fetchPreviewOverride: (url) async => {},
          postLinkOverride: (token, baseUrl, link) =>
              throw Exception("Network Error"),
        ),
      ),
    );
    await tester.pumpAndSettle();

    mockCollectionsReplayer.publish([
      Collection(id: 1, name: "Col A", ownerId: 1),
    ], currentKey: ui.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Collection>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Col A').last);
    await tester.pumpAndSettle();

    final urlField = find.widgetWithText(TextFormField, "Link").first;
    await tester.enterText(urlField, 'https://example.com');
    await tester.pump();

    final nameField = find.widgetWithText(TextFormField, "Name").first;
    await tester.enterText(nameField, 'My Link');
    await tester.pump();

    final submitButton = find.widgetWithText(FilledButton, 'Submit');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('https://example.com'), findsOneWidget);
    expect(find.text('My Link'), findsOneWidget);
    expect(
      find.text(
        'Failed to submit link. Please check your connection and try again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('successful submit and reset', (WidgetTester tester) async {
    final ui = UserInstance(
      id: '1',
      server: 'https://test.com',
      apiToken: 'token',
    );
    userInstanceValueReplayer.publish([ui]);

    await tester.pumpWidget(
      buildTestableWidget(
        AddLinkView(
          loadDefaultUserInstanceOverride: () async => ui.id,
          collectionsReplayerOverride: mockCollectionsReplayer,
          tagsReplayerOverride: mockTagsReplayer,
          fetchPreviewOverride: (url) async => {},
          postLinkOverride: (token, baseUrl, link) async =>
              Link(id: 1, name: "ok", url: "https://example.com"),
        ),
      ),
    );
    await tester.pumpAndSettle();

    mockCollectionsReplayer.publish([
      Collection(id: 1, name: "Col A", ownerId: 1),
    ], currentKey: ui.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Collection>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Col A').last);
    await tester.pumpAndSettle();

    final urlField = find.widgetWithText(TextFormField, "Link").first;
    await tester.enterText(urlField, 'https://example.com');
    await tester.pump();

    final submitButton = find.widgetWithText(FilledButton, 'Submit');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton, warnIfMissed: false);
    await tester.pump();
    await tester.pump();

    expect(find.text('https://example.com'), findsNothing);
    expect(find.text('Bookmark saved!'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('preview timeout/failure', (WidgetTester tester) async {
    final ui = UserInstance(
      id: '1',
      server: 'https://test.com',
      apiToken: 'token',
    );
    userInstanceValueReplayer.publish([ui]);

    await tester.pumpWidget(
      buildTestableWidget(
        AddLinkView(
          arguments: AddLinkViewArguments(link: "https://example.com"),
          loadDefaultUserInstanceOverride: () async => ui.id,
          collectionsReplayerOverride: mockCollectionsReplayer,
          tagsReplayerOverride: mockTagsReplayer,
          fetchPreviewOverride: (url) => throw Exception("Timeout"),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load preview'), findsOneWidget);
  });

  testWidgets('bad preview image handling fallback renders safely', (
    WidgetTester tester,
  ) async {
    final ui = UserInstance(
      id: '1',
      server: 'https://test.com',
      apiToken: 'token',
    );
    userInstanceValueReplayer.publish([ui]);

    await tester.pumpWidget(
      buildTestableWidget(
        AddLinkView(
          arguments: AddLinkViewArguments(link: "https://example.com"),
          loadDefaultUserInstanceOverride: () async => ui.id,
          collectionsReplayerOverride: mockCollectionsReplayer,
          tagsReplayerOverride: mockTagsReplayer,
          fetchPreviewOverride: (url) async => {
            "title": "Title",
            "image": "http://invalid-image",
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final imageWidget = tester.widget<Image>(find.byType(Image));
    expect(imageWidget.errorBuilder, isNotNull);
  });

  testWidgets('instance A -> B state invalidation preserves drafts', (
    WidgetTester tester,
  ) async {
    final uiA = UserInstance(
      id: '1',
      server: 'https://test.com',
      apiToken: 'token',
    );
    final uiB = UserInstance(
      id: '2',
      server: 'https://test2.com',
      apiToken: 'token',
    );
    userInstanceValueReplayer.publish([uiA, uiB]);

    mockCollectionsReplayer.publish([
      Collection(id: 1, name: "Coll A", ownerId: 1),
    ], currentKey: uiA.id);

    await tester.pumpWidget(
      buildTestableWidget(
        AddLinkView(
          loadDefaultUserInstanceOverride: () async => uiA.id,
          collectionsReplayerOverride: mockCollectionsReplayer,
          tagsReplayerOverride: mockTagsReplayer,
          fetchPreviewOverride: (url) async => {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Add draft
    final urlField = find.widgetWithText(TextFormField, "Link").first;
    await tester.enterText(urlField, 'https://example.com');
    await tester.pump();

    expect(find.text('https://test.com'), findsOneWidget);

    await tester.tap(find.text('https://test.com'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('https://test2.com').last);
    await tester.pumpAndSettle();

    expect(find.text('https://test2.com'), findsOneWidget);
    expect(find.text('https://example.com'), findsOneWidget); // draft preserved
  });

  testWidgets('instance A -> no instance state invalidation', (
    WidgetTester tester,
  ) async {
    final uiA = UserInstance(
      id: '1',
      server: 'https://test.com',
      apiToken: 'token',
    );
    userInstanceValueReplayer.publish([uiA]);

    await tester.pumpWidget(
      buildTestableWidget(
        AddLinkView(
          loadDefaultUserInstanceOverride: () async => uiA.id,
          collectionsReplayerOverride: mockCollectionsReplayer,
          tagsReplayerOverride: mockTagsReplayer,
          fetchPreviewOverride: (url) async => {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('https://test.com'), findsOneWidget);

    await tester.tap(find.text('https://test.com'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New').last);
    await tester.pumpAndSettle();

    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('newly created collection then instance switch', (
    WidgetTester tester,
  ) async {
    final uiA = UserInstance(
      id: '1',
      server: 'https://test.com',
      apiToken: 'token',
    );
    final uiB = UserInstance(
      id: '2',
      server: 'https://test2.com',
      apiToken: 'token',
    );
    userInstanceValueReplayer.publish([uiA, uiB]);

    await tester.pumpWidget(
      buildTestableWidget(
        AddLinkView(
          loadDefaultUserInstanceOverride: () async => uiA.id,
          collectionsReplayerOverride: mockCollectionsReplayer,
          tagsReplayerOverride: mockTagsReplayer,
          fetchPreviewOverride: (url) async => {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Simulate collection being added
    mockCollectionsReplayer.publish([
      Collection(id: 1, name: "New Coll", ownerId: 1),
    ], currentKey: uiA.id);
    await tester.pumpAndSettle();

    // Switch to B
    await tester.tap(find.text('https://test.com'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('https://test2.com').last);
    await tester.pumpAndSettle();

    expect(find.text('https://test2.com'), findsOneWidget);
  });

  testWidgets('submit failure when postLink returns null', (
    WidgetTester tester,
  ) async {
    final ui = UserInstance(
      id: '1',
      server: 'https://test.com',
      apiToken: 'token',
    );
    userInstanceValueReplayer.publish([ui]);

    await tester.pumpWidget(
      buildTestableWidget(
        AddLinkView(
          loadDefaultUserInstanceOverride: () async => ui.id,
          collectionsReplayerOverride: mockCollectionsReplayer,
          tagsReplayerOverride: mockTagsReplayer,
          fetchPreviewOverride: (url) async => {},
          postLinkOverride: (token, baseUrl, link) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    mockCollectionsReplayer.publish([
      Collection(id: 1, name: "Col A", ownerId: 1),
    ], currentKey: ui.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Collection>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Col A').last);
    await tester.pumpAndSettle();

    final urlField = find.widgetWithText(TextFormField, "Link").first;
    await tester.enterText(urlField, 'https://example.com');
    await tester.pump();

    final submitButton = find.widgetWithText(FilledButton, 'Submit');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('https://example.com'), findsOneWidget);
    expect(
      find.text(
        'Failed to submit link. Please check your connection and try again.',
      ),
      findsOneWidget,
    );
  });
}
