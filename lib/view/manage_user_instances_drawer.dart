import 'package:flutter/material.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';
import 'package:send_to_linkwarden/view/add_edit_user_instance_view.dart';

class ManageUserInstancesDrawer extends StatelessWidget {
  const ManageUserInstancesDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: StreamBuilder(
        stream: userInstanceValueReplayer.subscribe(),
        builder: (context, AsyncSnapshot<List<UserInstance>> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading instances: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var instances = snapshot.data ?? [];
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                child: Text('Manage Linkwarden Instances'),
              ),
              for (UserInstance instance in instances)
                ListTile(
                  title: Text(instance.server ?? 'Unknown URL'),
                  subtitle: Text(instance.user ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          Navigator.pop(context);
                          var result = await Navigator.pushNamed(
                            context,
                            'userInstance/newEdit',
                            arguments: AddEditUserInstanceViewArguments(userInstance: instance),
                          );
                          if (result is UserInstance) {
                            upsertUserInstance(result);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Instance'),
                              content: const Text('Are you sure you want to delete this instance?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            deleteUserInstance(instance);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Instance'),
                onTap: () async {
                  Navigator.pop(context);
                  var result = await Navigator.pushNamed(
                    context,
                    'userInstance/newEdit',
                    arguments: const AddEditUserInstanceViewArguments(),
                  );
                  if (result is UserInstance) {
                    upsertUserInstance(result);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
