import 'package:json_annotation/json_annotation.dart';

part 'collection.g.dart';

@JsonSerializable()
class Collection {
  int? id;
  String? name;
  String? color;
  String? description;
  bool? isPublic;
  dynamic members;
  dynamic parent;
  int? ownerId;
  int? parentId;
  String? createdAt;
  String? updatedAt;

  Collection({
    this.id,
    this.name,
    this.color,
    this.description,
    this.isPublic,
    this.members,
    this.parent,
    this.ownerId,
    this.parentId,
    this.createdAt,
    this.updatedAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) => _$CollectionFromJson(json);

  Map<String, dynamic> toJson() => _$CollectionToJson(this);
}