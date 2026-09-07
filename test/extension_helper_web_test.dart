@TestOn('chrome')
library;

import 'dart:js_interop';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_to_linkwarden/util/extension_helper_web.dart';

@JS()
external void eval(String code);

void main() {
  group('getCurrentTabUrl web implementation', () {
    test('returns null when no extension APIs exist', () async {
      final url = await getCurrentTabUrl();
      expect(url, isNull);
    });

    test('handles Chrome tabs.query with valid response', () async {
      eval('''
        window.chrome = {
          tabs: {
            query: function(queryInfo, callback) {
              callback([{ url: 'https://example.com/chrome' }]);
            }
          }
        };
      ''');
      final url = await getCurrentTabUrl();
      expect(url, 'https://example.com/chrome');

      eval('delete window.chrome;');
    });

    test('handles Chrome tabs.query returning empty list', () async {
      eval('''
        window.chrome = {
          tabs: {
            query: function(queryInfo, callback) {
              callback([]);
            }
          }
        };
      ''');
      final url = await getCurrentTabUrl();
      expect(url, isNull);

      eval('delete window.chrome;');
    });

    test(
      'handles Chrome tabs.query with runtime error (undefined callback argument)',
      () async {
        eval('''
        window.chrome = {
          tabs: {
            query: function(queryInfo, callback) {
              // Simulate missing permissions error where tabs is undefined
              callback(undefined);
            }
          }
        };
      ''');
        final url = await getCurrentTabUrl();
        expect(url, isNull);

        eval('delete window.chrome;');
      },
    );

    test('handles Firefox browser.tabs.query with valid response', () async {
      eval('''
        window.browser = {
          tabs: {
            query: function(queryInfo) {
              return Promise.resolve([{ url: 'https://example.com/firefox' }]);
            }
          }
        };
      ''');
      final url = await getCurrentTabUrl();
      expect(url, 'https://example.com/firefox');

      eval('delete window.browser;');
    });

    test('handles Firefox browser.tabs.query returning empty list', () async {
      eval('''
        window.browser = {
          tabs: {
            query: function(queryInfo) {
              return Promise.resolve([]);
            }
          }
        };
      ''');
      final url = await getCurrentTabUrl();
      expect(url, isNull);

      eval('delete window.browser;');
    });

    test('handles Firefox browser.tabs.query promise rejection', () async {
      eval('''
        window.browser = {
          tabs: {
            query: function(queryInfo) {
              return Promise.reject(new Error("Permission denied"));
            }
          }
        };
      ''');
      final url = await getCurrentTabUrl();
      expect(url, isNull);

      eval('delete window.browser;');
    });
  });
}
