import 'package:uuid/uuid.dart';

class UserInstance {
  late String id;
  String? user;
  String? server;
  String? password;

  UserInstance({
    String? id,
    this.user,
    this.server,
    this.password,
  }) : id = id ?? const Uuid().v4();
}
