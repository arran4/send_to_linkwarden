import 'package:uuid/uuid.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_instance.g.dart';

@JsonSerializable()
class UserInstance {
  late String id;
  String? user;
  String? server;
  String? password;
  String? apiToken;

  UserInstance({
    String? id,
    this.user,
    this.server,
    this.password,
    this.apiToken,
  }) : id = id ?? const Uuid().v4();

  factory UserInstance.fromJson(Map<String, dynamic> json) => _$UserInstanceFromJson(json);

  Map<String, dynamic> toJson() => _$UserInstanceToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserInstance &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
