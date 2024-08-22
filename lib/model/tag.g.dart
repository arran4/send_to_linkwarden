// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TagCount _$TagCountFromJson(Map<String, dynamic> json) => TagCount(
      links: (json['links'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TagCountToJson(TagCount instance) => <String, dynamic>{
      'links': instance.links,
    };

Tag _$TagFromJson(Map<String, dynamic> json) => Tag(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      ownerId: (json['ownerId'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      count: json['_count'] == null
          ? null
          : TagCount.fromJson(json['_count'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TagToJson(Tag instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'ownerId': instance.ownerId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      '_count': instance.count,
    };
