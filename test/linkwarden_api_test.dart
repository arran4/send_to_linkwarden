import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:send_to_linkwarden/api/linkwarden.dart';

void main() {
  group('Linkwarden API - Tags', () {
    String loadFixture(String name) =>
        File('test/fixtures/$name').readAsStringSync();

    test('getTags parses legacy response format correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(loadFixture('tags_legacy.json'), 200);
      });

      final tags = await getTags(
        'test_token',
        'https://example.com',
        client: mockClient,
      );

      expect(tags, isNotNull);
      expect(tags!.length, 1);
      expect(tags[0].name, 'tag1');
    });

    test('getTags parses new single-page response format correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(loadFixture('tags_paginated_single.json'), 200);
      });

      final tags = await getTags(
        'test_token',
        'https://example.com',
        client: mockClient,
      );

      expect(tags, isNotNull);
      expect(tags!.length, 1);
      expect(tags[0].name, 'tag1');
    });

    test(
      'getTags parses new multi-page response format and loops correctly',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.queryParameters['cursor'] == '2') {
            return http.Response(
              loadFixture('tags_paginated_multi_p2.json'),
              200,
            );
          } else {
            return http.Response(
              loadFixture('tags_paginated_multi_p1.json'),
              200,
            );
          }
        });

        final tags = await getTags(
          'test_token',
          'https://example.com',
          client: mockClient,
        );

        expect(tags, isNotNull);
        expect(tags!.length, 2);
        expect(tags[0].name, 'tag1');
        expect(tags[1].name, 'tag2');
      },
    );

    test(
      'getTags prioritizes data.tags over legacy response when both exist',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(loadFixture('tags_dual_shape.json'), 200);
        });

        final tags = await getTags(
          'test_token',
          'https://example.com',
          client: mockClient,
        );

        expect(tags, isNotNull);
        expect(tags!.length, 1);
        expect(tags[0].name, 'tag1'); // Not 'legacy_tag_should_be_ignored'
      },
    );

    test('getTags throws FormatException on legacy malformed type', () async {
      final mockClient = MockClient((request) async {
        return http.Response(loadFixture('tags_malformed_1.json'), 200);
      });

      expect(
        () => getTags('test_token', 'https://example.com', client: mockClient),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'getTags throws FormatException on paginated malformed type',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(loadFixture('tags_malformed_2.json'), 200);
        });

        expect(
          () =>
              getTags('test_token', 'https://example.com', client: mockClient),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('getTags throws FormatException on top-level non-object', () async {
      final mockClient = MockClient((request) async {
        return http.Response(loadFixture('tags_malformed_top_level.json'), 200);
      });

      expect(
        () => getTags('test_token', 'https://example.com', client: mockClient),
        throwsA(isA<FormatException>()),
      );
    });

    test('getTags throws FormatException on non-object tag elements', () async {
      final mockClient = MockClient((request) async {
        return http.Response(loadFixture('tags_malformed_element.json'), 200);
      });

      expect(
        () => getTags('test_token', 'https://example.com', client: mockClient),
        throwsA(isA<FormatException>()),
      );
    });

    test('getTags throws FormatException on wrong cursor type', () async {
      final mockClient = MockClient((request) async {
        return http.Response(loadFixture('tags_malformed_cursor.json'), 200);
      });

      expect(
        () => getTags('test_token', 'https://example.com', client: mockClient),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'getTags breaks infinite loops caused by repeated cursor and throws',
      () async {
        final mockClient = MockClient((request) async {
          // Always return cursor 1 to cause a loop
          return http.Response(
            json.encode({
              "data": {
                "tags": [
                  {"id": 1, "name": "loop"},
                ],
                "nextCursor": 1,
              },
            }),
            200,
          );
        });

        expect(
          () =>
              getTags('test_token', 'https://example.com', client: mockClient),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'getTags throws FormatException on malformed tag field type',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(loadFixture('tags_malformed_field.json'), 200);
        });

        expect(
          () =>
              getTags('test_token', 'https://example.com', client: mockClient),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('getTags throws FormatException on malformed _count field', () async {
      final mockClient = MockClient((request) async {
        return http.Response(loadFixture('tags_malformed_count.json'), 200);
      });

      expect(
        () => getTags('test_token', 'https://example.com', client: mockClient),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
