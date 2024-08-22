import 'package:uuid/uuid.dart';

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
}
