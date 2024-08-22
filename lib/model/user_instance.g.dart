// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_instance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInstance _$UserInstanceFromJson(Map<String, dynamic> json) => UserInstance(
      id: json['id'] as String?,
      user: json['user'] as String?,
      server: json['server'] as String?,
      password: json['password'] as String?,
      apiToken: json['apiToken'] as String?,
    );

Map<String, dynamic> _$UserInstanceToJson(UserInstance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'server': instance.server,
      'password': instance.password,
      'apiToken': instance.apiToken,
    };
