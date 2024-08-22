import 'package:linkwarden_mobile/api/linkwarden.dart';
import 'package:linkwarden_mobile/core/individual_keyed_pub_sub_replay.dart';
import 'package:linkwarden_mobile/model/collection.dart';
import 'package:linkwarden_mobile/model/user_instance.dart';
import 'package:linkwarden_mobile/state/user_instance_replayer.dart';

final IndividualKeyedPubSubReplay<String?, List<Collection>?> collectionsReplayer = IndividualKeyedPubSubReplay<String?, List<Collection>?>(onNoLastMessage: (queue, currentKey) async {
  if (currentKey == null) {
    queue.publish([], currentKey: currentKey);
    return;
  }
  UserInstance? ui = await getUserInstanceById(currentKey);
  if (ui == null) {
    queue.publish([], currentKey: currentKey);
    return;
  }
  var collections = await getCollections(ui.apiToken??"", ui.server??"");
  queue.publish(collections, currentKey: currentKey);
});
