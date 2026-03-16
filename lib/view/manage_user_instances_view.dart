import 'package:flutter/material.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';
import 'package:send_to_linkwarden/view/add_edit_user_instance_view.dart';

class ManageUserInstancesView extends StatefulWidget {
  const ManageUserInstancesView({super.key});

  @override
  State<ManageUserInstancesView> createState() =>
      _ManageUserInstancesViewState();
}

class _ManageUserInstancesViewState extends State<ManageUserInstancesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Linkwarden Instances')),
      body: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StreamBuilder(
                  stream: userInstanceValueReplayer.subscribe(),
                  builder: (context, AsyncSnapshot<List<UserInstance>> snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading instances: ${snapshot.error}',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var instances = snapshot.data ?? [];
                    return Column(
                      children: [
                        ReorderableListView(
                          shrinkWrap: true,
                          onReorder: (oldIndex, newIndex) {
                            reorderUserInstances(oldIndex, newIndex);
                          },
                          children: [
                            for (UserInstance instance in instances)
                              ListTile(
                                key: ValueKey(instance.id),
                                title: Text(instance.server ?? 'Unknown URL'),
                                subtitle: Text(instance.user ?? ''),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        var result = await Navigator.pushNamed(
                                          context,
                                          'userInstance/newEdit',
                                          arguments:
                                              AddEditUserInstanceViewArguments(
                                                userInstance: instance,
                                              ),
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
                                            title: const Text(
                                              'Delete Instance',
                                            ),
                                            content: const Text(
                                              'Are you sure you want to delete this instance?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          try {
                                            await deleteUserInstance(instance);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Instance deleted successfully.',
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (error) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Failed to delete instance: $error',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        ListTile(
                          key: const ValueKey('add'),
                          leading: const Icon(Icons.add),
                          title: const Text('Add Instance'),
                          onTap: () async {
                            var result = await Navigator.pushNamed(
                              context,
                              'userInstance/newEdit',
                              arguments:
                                  const AddEditUserInstanceViewArguments(),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
