import 'package:send_to_linkwarden/api/linkwarden.dart';
import 'package:send_to_linkwarden/core/individual_keyed_pub_sub_replay.dart';
import 'package:send_to_linkwarden/model/tag.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';

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