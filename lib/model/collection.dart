import 'package:uuid/uuid.dart';

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
}
