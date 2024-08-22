import 'package:json_annotation/json_annotation.dart';

part 'tag.g.dart';

@JsonSerializable()
class TagCount {
  final int? links;

  TagCount({this.links});

  factory TagCount.fromJson(Map<String, dynamic> json) => _$TagCountFromJson(json);

  Map<String, dynamic> toJson() => _$TagCountToJson(this);
}

@JsonSerializable()
class Tag {
  final int? id;
  final String? name;
  final int? ownerId;
  final String? createdAt;
  final String? updatedAt;

  @JsonKey(name: '_count')
  final TagCount? count;

  Tag({
    this.id,
    this.name,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
    this.count,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Tag &&
              runtimeType == other.runtimeType &&
              ((id != null && other.id != null && id == other.id) || (name == other.name));

  @override
  int get hashCode => id?.hashCode ?? name.hashCode;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);

  Map<String, dynamic> toJson() => _$TagToJson(this);
}
