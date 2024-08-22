// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Collection _$CollectionFromJson(Map<String, dynamic> json) => Collection(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      color: json['color'] as String?,
      description: json['description'] as String?,
      isPublic: json['isPublic'] as bool?,
      members: json['members'],
      parent: json['parent'],
      ownerId: (json['ownerId'] as num?)?.toInt(),
      parentId: (json['parentId'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$CollectionToJson(Collection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
      'description': instance.description,
      'isPublic': instance.isPublic,
      'members': instance.members,
      'parent': instance.parent,
      'ownerId': instance.ownerId,
      'parentId': instance.parentId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
