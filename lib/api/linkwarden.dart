import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:linkwarden_mobile/model/tag.dart';
import 'package:linkwarden_mobile/model/collection.dart';
import 'package:linkwarden_mobile/model/link.dart';

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
