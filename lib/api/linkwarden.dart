import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:send_to_linkwarden/model/tag.dart';
import 'package:send_to_linkwarden/model/collection.dart';
import 'package:send_to_linkwarden/model/link.dart';
import 'package:html/parser.dart' as html;

Future<List<Tag>?> getTags(String token, String baseUrl) async {
  final url = Uri.parse('$baseUrl/api/v1/tags');

  final headers = {
    HttpHeaders.authorizationHeader: 'Bearer $token',
    HttpHeaders.acceptHeader: 'application/json',
  };

  final response = await http.get(url, headers: headers);

  if (response.statusCode < 200 || response.statusCode > 299) {
    throw HttpException('Failed to load tags: ${response.statusCode}');
  }

  final Map<String, dynamic> responseObject = json.decode(response.body);

  if (responseObject['response'] == null) {
    throw const FormatException('Invalid response structure');
  }

  final List<Tag> tags = (responseObject['response'] as List)
      .map((tagJson) => Tag.fromJson(tagJson))
      .toList();

  return tags;
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

Future<Collection?> createCollection(String token, String baseUrl, Collection collection) async {
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
    "collection": link.collection != null ? {
      "id": link.collection?.id,
      "ownerId": link.collection?.ownerId,
      "name": link.collection?.name,
    } : null,
    "tags": (link.tags??[]).map((e) {
      return {
        "id": e.id,
        "name": e.name,
        };
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

Future<String> createSession(String baseUrl, String username, String password) async {
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

  if (responseObject['response'] == null || responseObject['response']['token'] == null) {
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
    final response = await client.send(request).timeout(const Duration(seconds: 1));

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

    final document = html.parse(utf8.decode(bytes));
    String? title = document.querySelector('title')?.text;
    title ??= document.querySelector('meta[property="og:title"]')?.attributes['content'];
    title ??= document.querySelector('meta[name="twitter:title"]')?.attributes['content'];

    String? description = document.querySelector('meta[name="description"]')?.attributes['content'];
    description ??= document.querySelector('meta[property="og:description"]')?.attributes['content'];
    description ??= document.querySelector('meta[name="twitter:description"]')?.attributes['content'];

    String? image = document.querySelector('meta[property="og:image"]')?.attributes['content'];
    image ??= document.querySelector('meta[name="twitter:image"]')?.attributes['content'];

    return {
      'title': title,
      'description': description,
      'image': image,
    };
  } finally {
    client.close();
  }
}
