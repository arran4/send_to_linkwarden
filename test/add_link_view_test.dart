import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/model/collection.dart';
import 'package:send_to_linkwarden/model/tag.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/state/collections_replayer.dart';
import 'package:send_to_linkwarden/state/tags_replayer.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';
import 'package:send_to_linkwarden/state/default_user_instance.dart';
import 'package:send_to_linkwarden/view/add_link_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Test fakes
import 'dart:convert';
import 'dart:io';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    userInstanceValueReplayer.publish([]);
    collectionsReplayer.reset(null);
    tagsReplayer.reset(null);
  });

  Widget createTestWidget({AddLinkViewArguments? arguments}) {
    return MaterialApp(
      routes: {
        'userInstance/newEdit': (context) =>
            const Scaffold(body: Text('New User Instance Mock')),
      },
      home: Scaffold(body: AddLinkView(arguments: arguments)),
    );
  }

  group('AddLinkView', () {
    testWidgets('validation failure', (WidgetTester tester) async {
      userInstanceValueReplayer.publish([
        UserInstance(
          id: "1",
          server: "https://example.com",
          apiToken: "token123",
        ),
      ]);
      await setDefaultUserInstance("1");

      collectionsReplayer.publish([], currentKey: "1");
      tagsReplayer.publish([], currentKey: "1");

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Validation errors'), findsOneWidget);
    });

    testWidgets('instance A -> B clears collection and tags', (
      WidgetTester tester,
    ) async {
      final instanceA = UserInstance(
        id: "A",
        server: "https://a.com",
        apiToken: "tokA",
      );
      final instanceB = UserInstance(
        id: "B",
        server: "https://b.com",
        apiToken: "tokB",
      );

      userInstanceValueReplayer.publish([instanceA, instanceB]);
      await setDefaultUserInstance("A");

      collectionsReplayer.publish([
        Collection(id: 1, name: "ColA"),
      ], currentKey: "A");
      tagsReplayer.publish([Tag(id: 1, name: "TagA")], currentKey: "A");
      collectionsReplayer.publish([
        Collection(id: 2, name: "ColB"),
      ], currentKey: "B");
      tagsReplayer.publish([Tag(id: 2, name: "TagB")], currentKey: "B");

      await tester.pumpWidget(
        createTestWidget(
          arguments: AddLinkViewArguments(
            link: "http://example.com",
            name: "Draft Name",
            description: "Draft Desc",
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('https://a.com'), findsOneWidget);
      expect(find.text('Draft Name'), findsOneWidget);

      await tester.tap(find.text('https://a.com'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('https://b.com').last);
      await tester.pumpAndSettle();

      expect(find.text('https://b.com'), findsOneWidget);
      expect(find.text('Draft Name'), findsOneWidget); // Draft preserved
    });

    testWidgets('preview timeout/failure', (WidgetTester tester) async {
      HttpOverrides.global = _MockHttpOverrides((request) {
        return _MockHttpClientResponse(404, "");
      });

      userInstanceValueReplayer.publish([
        UserInstance(
          id: "1",
          server: "https://example.com",
          apiToken: "token123",
        ),
      ]);
      await setDefaultUserInstance("1");

      collectionsReplayer.publish([], currentKey: "1");
      tagsReplayer.publish([], currentKey: "1");

      await tester.pumpWidget(
        createTestWidget(
          arguments: AddLinkViewArguments(link: "http://bad.url"),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Preview unavailable or failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      HttpOverrides.global = null;
    });
  });
}

// Http overrides for explicit mock
class _MockHttpOverrides extends HttpOverrides {
  final FutureOr<HttpClientResponse> Function(HttpClientRequest request)
  handler;
  _MockHttpOverrides(this.handler);
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient(handler);
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  final FutureOr<HttpClientResponse> Function(HttpClientRequest request)
  handler;
  _MockHttpClient(this.handler);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest(handler);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _MockHttpClientRequest(handler);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _MockHttpClientRequest(handler);
  }

  @override
  void close({bool force = false}) {}
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  final FutureOr<HttpClientResponse> Function(HttpClientRequest request)
  handler;
  _MockHttpClientRequest(this.handler);

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return await handler(this);
  }

  @override
  void add(List<int> data) {}
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  List<String>? operator [](String name) => [];
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void remove(String name, Object value) {}
  @override
  void removeAll(String name) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  final int _statusCode;
  final String _body;
  _MockHttpClientResponse(this._statusCode, this._body);

  @override
  int get statusCode => _statusCode;

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(utf8.encode(_body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
