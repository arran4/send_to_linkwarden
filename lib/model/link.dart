import 'package:json_annotation/json_annotation.dart';
import 'package:linkwarden_mobile/model/collection.dart';
import 'package:linkwarden_mobile/model/tag.dart';

part 'link.g.dart';

@JsonSerializable()
class Link {
  final int? id;
  final String? name;
  final String? description;
  final String? url;
  final Collection? collection;
  final List<Tag>? tags;
  final dynamic parent;
  final int? ownerId;
  final String? createdAt;
  final String? updatedAt;
  final String? type;
  @JsonKey(name: 'collection_id')
  final int? collectionId;
  final dynamic textContent;
  final dynamic preview;
  final dynamic image;
  final dynamic pdf;
  final dynamic readable;
  final dynamic monolith;
  final dynamic lastPreserved;
  final dynamic importDate;

  Link({
    this.id,
    this.name,
    this.description,
    this.url,
    this.collection,
    this.tags,
    this.parent,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
    this.type,
    this.collectionId,
    this.textContent,
    this.preview,
    this.image,
    this.pdf,
    this.readable,
    this.monolith,
    this.lastPreserved,
    this.importDate,
  });

  factory Link.fromJson(Map<String, dynamic> json) => _$LinkFromJson(json);

  Map<String, dynamic> toJson() => _$LinkToJson(this);
}
