import 'package:linkwarden_mobile/api/linkwarden.dart';
import 'package:linkwarden_mobile/core/individual_keyed_pub_sub_replay.dart';
import 'package:linkwarden_mobile/model/tag.dart';
import 'package:linkwarden_mobile/model/user_instance.dart';
import 'package:linkwarden_mobile/state/user_instance_replayer.dart';

final IndividualKeyedPubSubReplay<String?, List<Tag>?> tagsReplayer = IndividualKeyedPubSubReplay<String?, List<Tag>?>(onNoLastMessage: (queue, currentKey) async {
  if (currentKey == null) {
    queue.publish([], currentKey: currentKey);
    return;
  }
  UserInstance? ui = await getUserInstanceById(currentKey);
  if (ui == null) {
    queue.publish([], currentKey: currentKey);
    return;
  }
  queue.publish(await getTags(ui.apiToken??"", ui.server??""), currentKey: currentKey);
});