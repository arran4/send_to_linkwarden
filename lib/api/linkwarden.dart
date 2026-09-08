import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:send_to_linkwarden/model/tag.dart';
import 'package:send_to_linkwarden/model/collection.dart';
import 'package:send_to_linkwarden/model/link.dart';
import 'package:html/parser.dart' as html;

Future<List<Tag>?> getTags(
  String token,
  String baseUrl, {
  http.Client? client,
}) async {
  final bool ownsClient = client == null;
  final httpClient = client ?? http.Client();

  final headers = {
    HttpHeaders.authorizationHeader: 'Bearer $token',
    HttpHeaders.acceptHeader: 'application/json',
  };

  final List<Tag> allTags = [];
  int? nextCursor;
  int loopCount = 0;
  final int maxLoops = 1000;
  final Set<int> seenCursors = {};

  try {
    do {
      if (nextCursor != null) {
        if (seenCursors.contains(nextCursor)) {
          throw const FormatException('Repeated cursor');
        }
        seenCursors.add(nextCursor);
      }

      final uri = nextCursor != null
          ? Uri.parse('$baseUrl/api/v1/tags?cursor=$nextCursor')
          : Uri.parse('$baseUrl/api/v1/tags');

      final response = await httpClient.get(uri, headers: headers);

      if (response.statusCode < 200 || response.statusCode > 299) {
        throw HttpException('Failed to load tags: ${response.statusCode}');
      }

      final dynamic decoded = json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid response structure');
      }

      final data = decoded['data'];

      if (data is Map<String, dynamic> && data['tags'] is List) {
        // Authoritative paginated response format
        final List<Tag> tags = [];
        for (var tagJson in data['tags'] as List) {
          if (tagJson is! Map<String, dynamic>) {
            throw const FormatException('Invalid tag element structure');
          }
          try {
            tags.add(Tag.fromJson(tagJson));
          } catch (e) {
            throw const FormatException('Invalid tag field type');
          }
        }
        allTags.addAll(tags);

        final nextCursorValue = data['nextCursor'];
        if (nextCursorValue != null && nextCursorValue is! int) {
          throw const FormatException('Invalid nextCursor type');
        }
        nextCursor = nextCursorValue as int?;
      } else if (decoded['response'] is List) {
        // Fallback to legacy top-level unpaginated list
        final List<Tag> tags = [];
        for (var tagJson in decoded['response'] as List) {
          if (tagJson is! Map<String, dynamic>) {
            throw const FormatException('Invalid tag element structure');
          }
          try {
            tags.add(Tag.fromJson(tagJson));
          } catch (e) {
            throw const FormatException('Invalid tag field type');
          }
        }
        allTags.addAll(tags);
        break; // No pagination in legacy
      } else {
        throw const FormatException('Invalid response structure');
      }

      loopCount++;
      if (loopCount >= maxLoops) {
        throw const HttpException('Max pages exceeded');
      }
    } while (nextCursor != null);
  } finally {
    if (ownsClient) {
      httpClient.close();
    }
  }

  return allTags;
}

Future<List<Collection>?> getCollections(String token, String baseUrl) async {
  final url = Uri.parse('$baseUrl/api/v1/collections');

  final headers = {
    HttpHeaders.authorizationHeader: 'Bearer $token',
    HttpHeaders.acceptHeader: 'application/json',
  };

  final response = await http.get(url, headers: headers);

  if (response.statusCode < 200 || response.statusCode > 299) {
    throw HttpException('Failed to load collections: ${response.statusCode}');
  }

  final Map<String, dynamic> responseObject = json.decode(response.body);

  if (responseObject['response'] == null) {
    throw const FormatException('Invalid response structure');
  }

  final List<Collection> collections = (responseObject['response'] as List)
      .map((collectionJson) => Collection.fromJson(collectionJson))
      .toList();

  return collections;
}

Future<Collection?> createCollection(
  String token,
  String baseUrl,
  Collection collection,
) async {
  final url = Uri.parse('$baseUrl/api/v1/collections');

  final headers = {
    HttpHeaders.authorizationHeader: 'Bearer $token',
    HttpHeaders.acceptHeader: 'application/json',
    HttpHeaders.contentTypeHeader: 'application/json',
  };

  final body = json.encode({
    "name": collection.name,
    "color": collection.color,
    "description": collection.description,
    "isPublic": collection.isPublic,
    "parentId": collection.parentId,
  });

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode < 200 || response.statusCode > 299) {
    throw HttpException('Failed to create collection: ${response.statusCode}');
  }

  final Map<String, dynamic> responseObject = json.decode(response.body);

  if (responseObject['response'] == null) {
    throw const FormatException('Invalid response structure');
  }

  return Collection.fromJson(responseObject['response']);
}

Future<Link?> postLink(String token, String baseUrl, Link link) async {
  final url = Uri.parse('$baseUrl/api/v1/links');

  final headers = {
    HttpHeaders.authorizationHeader: 'Bearer $token',
    HttpHeaders.acceptHeader: 'application/json',
    HttpHeaders.contentTypeHeader: 'application/json',
  };

  var data = {
    "name": link.name,
    "description": link.description,
    "url": link.url,
    "collection": link.collection != null
        ? {
            "id": link.collection?.id,
            "ownerId": link.collection?.ownerId,
            "name": link.collection?.name,
          }
        : null,
    "tags": (link.tags ?? []).map((e) {
      return {"id": e.id, "name": e.name};
    }).toList(),
  };

  final body = json.encode(data);

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode < 200 || response.statusCode > 299) {
    throw HttpException('Failed to post link: ${response.statusCode}');
  }

  final Map<String, dynamic> responseObject = json.decode(response.body);

  if (responseObject['response'] == null) {
    throw const FormatException('Invalid response structure');
  }

  return Link.fromJson(responseObject['response']);
}

Future<String> createSession(
  String baseUrl,
  String username,
  String password,
) async {
  final url = Uri.parse('$baseUrl/api/v1/session');

  final headers = {
    HttpHeaders.acceptHeader: 'application/json',
    HttpHeaders.contentTypeHeader: 'application/json',
  };

  final body = json.encode({
    'username': username,
    'password': password,
    'sessionName': 'Send To Linkwarden App',
  });

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode < 200 || response.statusCode > 299) {
    throw HttpException('Failed to login: ${response.statusCode}');
  }

  final Map<String, dynamic> responseObject = json.decode(response.body);

  if (responseObject['response'] == null ||
      responseObject['response']['token'] == null) {
    throw const FormatException('Invalid response structure');
  }

  return responseObject['response']['token'];
}

Future<Map<String, String?>> fetchPreview(String url) async {
  final uri = Uri.parse(url);
  final client = http.Client();
  try {
    final request = http.Request('GET', uri)
      ..headers[HttpHeaders.rangeHeader] = 'bytes=0-102399';
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 1));

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw HttpException('Failed to load preview: ${response.statusCode}');
    }

    final contentType = response.headers[HttpHeaders.contentTypeHeader];
    if (contentType == null || !contentType.contains('text/html')) {
      return {};
    }

    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      if (bytes.length > 102400) {
        bytes.removeRange(102400, bytes.length);
        break;
      }
    }

    return await compute(_parsePreviewFromBytes, Uint8List.fromList(bytes));
  } finally {
    client.close();
  }
}

Map<String, String?> _parsePreviewFromBytes(Uint8List bytes) {
  final document = html.parse(utf8.decode(bytes));
  String? title = document.querySelector('title')?.text;
  title ??= document
      .querySelector('meta[property="og:title"]')
      ?.attributes['content'];
  title ??= document
      .querySelector('meta[name="twitter:title"]')
      ?.attributes['content'];

  String? description = document
      .querySelector('meta[name="description"]')
      ?.attributes['content'];
  description ??= document
      .querySelector('meta[property="og:description"]')
      ?.attributes['content'];
  description ??= document
      .querySelector('meta[name="twitter:description"]')
      ?.attributes['content'];

  String? image = document
      .querySelector('meta[property="og:image"]')
      ?.attributes['content'];
  image ??= document
      .querySelector('meta[name="twitter:image"]')
      ?.attributes['content'];

  return {'title': title, 'description': description, 'image': image};
}
