import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:send_to_linkwarden/core/pub_sub_replay.dart';
import 'package:send_to_linkwarden/integrations/secure_storage.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/state/default_user_instance.dart';
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

void _ensureDefaultIsFirst(List<UserInstance> userInstances) {
  if (userInstances.isNotEmpty) {
    unawaited(setDefaultUserInstance(userInstances.first.id));
  } else {
    unawaited(setDefaultUserInstance(null));
  }
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
  _ensureDefaultIsFirst(current);
}

Future<void> deleteUserInstance(UserInstance instance) async {
  var sub = userInstanceValueReplayer.subscribe();
  List<UserInstance> current = [...await sub.first];
  current.removeWhere((e) => e.id == instance.id);
  userInstanceValueReplayer.publish(current);
  _saveUserInstances(current);
  if ((await loadDefaultUserInstance()) == instance.id) {
    await setDefaultUserInstance(null);
  }
  _ensureDefaultIsFirst(current);
}

void reorderUserInstances(int oldIndex, int newIndex) async {
  var sub = userInstanceValueReplayer.subscribe();
  List<UserInstance> current = [...await sub.first];
  if (newIndex > oldIndex) {
    newIndex -= 1;
  }
  final item = current.removeAt(oldIndex);
  current.insert(newIndex, item);
  userInstanceValueReplayer.publish(current);
  _saveUserInstances(current);
  _ensureDefaultIsFirst(current);
}
