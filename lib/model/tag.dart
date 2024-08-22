class TagCount {
  int? links;
}

class Tag {
  int? id;
  String? name;
  int? ownerId;
  String? createdAt;
  String? updatedAt;
  TagCount? count;

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
          ((id != null && other.id != null && id == other.id) ||
          (name == other.name));

  @override
  int get hashCode => id?.hashCode ?? name.hashCode;
}