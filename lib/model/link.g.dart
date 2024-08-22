// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Link _$LinkFromJson(Map<String, dynamic> json) => Link(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      description: json['description'] as String?,
      url: json['url'] as String?,
      collection: json['collection'] == null
          ? null
          : Collection.fromJson(json['collection'] as Map<String, dynamic>),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList(),
      parent: json['parent'],
      ownerId: (json['ownerId'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      type: json['type'] as String?,
      collectionId: (json['collection_id'] as num?)?.toInt(),
      textContent: json['textContent'],
      preview: json['preview'],
      image: json['image'],
      pdf: json['pdf'],
      readable: json['readable'],
      monolith: json['monolith'],
      lastPreserved: json['lastPreserved'],
      importDate: json['importDate'],
    );

Map<String, dynamic> _$LinkToJson(Link instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'url': instance.url,
      'collection': instance.collection,
      'tags': instance.tags,
      'parent': instance.parent,
      'ownerId': instance.ownerId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'type': instance.type,
      'collection_id': instance.collectionId,
      'textContent': instance.textContent,
      'preview': instance.preview,
      'image': instance.image,
      'pdf': instance.pdf,
      'readable': instance.readable,
      'monolith': instance.monolith,
      'lastPreserved': instance.lastPreserved,
      'importDate': instance.importDate,
    };
