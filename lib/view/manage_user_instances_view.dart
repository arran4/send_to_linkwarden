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
                      return const Center(
                        child: Text(
                          'Failed to load instances. Please try again.',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var instances = snapshot.data ?? [];
                    if (instances.isEmpty) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No Linkwarden instances configured.',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          ElevatedButton.icon(
                            key: const ValueKey('add_empty'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Instance'),
                            onPressed: () async {
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
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: instances.length,
                            onReorder: (oldIndex, newIndex) async {
                              try {
                                await reorderUserInstances(oldIndex, newIndex);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to reorder instances.')),
                                  );
                                }
                              }
                            },
                            itemBuilder: (context, index) {
                              final instance = instances[index];
                              final isDefault = index == 0;
                              return ListTile(
                                key: ValueKey(instance.id),
                                leading: Tooltip(
                                  message: isDefault
                                      ? 'Default instance'
                                      : 'Instance',
                                  child: Icon(
                                    isDefault ? Icons.star : Icons.dns,
                                    color: isDefault ? Colors.amber : null,
                                  ),
                                ),
                                title: Text(instance.server ?? 'Unknown URL'),
                                subtitle: Text(
                                  (instance.user ?? 'No User') +
                                      (isDefault ? ' (Default)' : ''),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Tooltip(
                                        message:
                                            'Drag to reorder and set default',
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.drag_handle),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Edit instance',
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
                                          try {
                                            await upsertUserInstance(result);
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Failed to save instance.')),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Delete instance',
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        bool? confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              'Delete Instance',
                                            ),
                                            content: Text(
                                              'Are you sure you want to delete ${instance.server}?',
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
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
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
                                              ).hideCurrentSnackBar();
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
                                              ).hideCurrentSnackBar();
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Failed to delete instance.',
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
                              );
                            },
                          ),
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
