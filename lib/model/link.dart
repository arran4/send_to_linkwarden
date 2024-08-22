import 'package:linkwarden_mobile/model/collection.dart';
import 'package:linkwarden_mobile/model/tag.dart';

class Link {
  int? id;
  String? name;
  String? description;
  String? url;
  Collection? collection;
  List<Tag>? tags;
  dynamic parent;
  int? ownerId;
  String? createdAt;
  String? updatedAt;
  String? type;
  int? collectionId;
  dynamic textContent;
  dynamic preview;
  dynamic image;
  dynamic pdf;
  dynamic readable;
  dynamic monolith;
  dynamic lastPreserved;
  dynamic importDate;
}
