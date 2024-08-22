import 'dart:convert';

import 'package:linkwarden_mobile/core/pub_sub_replay.dart';
import 'package:linkwarden_mobile/integrations/secure_storage.dart';
import 'package:linkwarden_mobile/model/user_instance.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

PubSubReplay<List<UserInstance>> userInstanceValueReplayer = PubSubReplay(onNoLastMessage: loadUserInstances);

void loadUserInstances(PubSubReplay<List<UserInstance>?> queue) async {
  final FlutterSecureStorage storage = getSecureStorage();
  String? stored = await storage.read(key: "UserInstancesV1");
  if (stored == null || stored == "" || stored == "{}" || stored == "[]") {
    queue.publish([]);
    return;
  }
  List<dynamic> unmarshalled = jsonDecode(stored);
  queue.publish(unmarshalled.map((each) => UserInstance.fromJson(each)).toList());
}

void _saveUserInstances(List<UserInstance> userInstances) async {
  late final FlutterSecureStorage storage = getSecureStorage();
  await storage.write(key: "UserInstancesV1", value: jsonEncode(userInstances));
}

Future<UserInstance?> getUserInstanceById(String? id) async {
  var sub = userInstanceValueReplayer.subscribe();
  return (await sub.first).firstWhere((e) => e.id == id);
}

void upsertUserInstance(UserInstance userInstances) async {
  var sub = userInstanceValueReplayer.subscribe();
  List<UserInstance> current = [...await sub.first];
  int p = current.indexOf(userInstances);
  if (p < 0) {
    current.add(userInstances);
  } else {
    current[p] = userInstances;
  }
  userInstanceValueReplayer.publish(current);
  _saveUserInstances(current);
}
