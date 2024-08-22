import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:linkwarden_mobile/api/linkwarden.dart';
import 'package:linkwarden_mobile/core/individual_keyed_pub_sub_replay.dart';
import 'package:linkwarden_mobile/model/collection.dart';
import 'package:linkwarden_mobile/model/tag.dart';
import 'package:linkwarden_mobile/model/user_instance.dart';
import 'package:linkwarden_mobile/state/collections_replayer.dart';
import 'package:linkwarden_mobile/state/dark_mode_notifier.dart';
import 'package:linkwarden_mobile/state/default_user_instance.dart';
import 'package:linkwarden_mobile/state/user_instance_replayer.dart';
import 'package:linkwarden_mobile/view/select_tags_view.dart';

import 'add_edit_user_instance_view.dart';

class AddLinkView extends StatefulWidget {
  const AddLinkView({super.key});

  @override
  State<AddLinkView> createState() => _AddLinkViewState();
}

class _AddLinkViewState extends State<AddLinkView> {
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  late List<String> tags;
  UserInstance? selectedUserInstance;
  bool selectedUserInstanceSet = false;
  Collection? selectedCollection;
  late IndividualKeyedPubSubReplayStream<String?, List<Collection>?> collectionsStream;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Add Bookmark - Linkwarden Mobile"),
        actions: [
          IconButton(onPressed: _darkMode, icon: const Icon(Icons.dark_mode)),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: formState,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _userAndInstanceSelection(context),
              _collectionSelection(context),
              _linkInput(context),
              ..._tagsSelection(context),
              _nameInput(context),
              _descriptionInput(context),
              _submitButton(context),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    tags = [];
    collectionsStream = collectionsReplayer.subscribe(initialKey: null);
  }


  @override
  void dispose() {
    super.dispose();
  }

  void _darkMode() async {
    setDarkMode(!darkModeNotifier.value);
  }

  Widget _submitButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: () {
          if (formState.currentState!.validate()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Processing Data')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Validation errors')),
            );
          }
        },
        child: const Text('Submit'),
      ),
    );
  }

  Widget _userAndInstanceSelection(BuildContext context) {
    return FutureBuilder(
      future: loadDefaultUserInstance(),
      builder: (context, defaultValueLoaded) {
        if (defaultValueLoaded.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Error loading default user instance: ${defaultValueLoaded.error}", style: const TextStyle(color: Colors.red)),
              ],
            ),
          );
        }
        if (defaultValueLoaded.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder(
          stream: userInstanceValueReplayer.subscribe(),
          builder: (BuildContext context, AsyncSnapshot<List<UserInstance>> list) {
            if (list.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Error loading user instances: ${list.error}", style: const TextStyle(color: Colors.red)),
                  ],
                ),
              );
            }
            if (list.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Should be a better way of doing this by combining the streams.
            if (!selectedUserInstanceSet && defaultValueLoaded.data != null && selectedUserInstance == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  selectedUserInstanceSet = true;
                });
                _selectNewUserInstance(list.requireData.where((each) => each.id == defaultValueLoaded.requireData).firstOrNull, makeDefault: false);
              });
            }
            if (!selectedUserInstanceSet && list.connectionState == ConnectionState.active) {
              WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                selectedUserInstanceSet = true;
              }));
            }
            return Flex(
              direction: Axis.horizontal,
              children: [
                Flexible(
                    child: DropdownButtonFormField(
                  decoration: const InputDecoration(
                    labelText: 'Select User And Linkwarden Instance',
                  ),
                  validator: (value) {
                    if (value == null) {
                      return "Please select an instance";
                    }
                    return null;
                  },
                  value: selectedUserInstance,
                  items: [
                    for (UserInstance ui in list.data??[])
                      DropdownMenuItem(
                        value: ui,
                        key: ValueKey(ui.id),
                        child: Text(ui.server??"Unknown URL"),
                      ),
                    const DropdownMenuItem(
                      value: null,
                      key: ValueKey("New"),
                      child: Text("New"),
                    ),
                  ],
                  onChanged: (value) {
                    _selectNewUserInstance(value, makeDefault: true);
                  },
                )),
                IconButton(
                    onPressed: () async {
                      var result =
                          await Navigator.pushNamed(context, "userInstance/newEdit", arguments: AddEditUserInstanceViewArguments(userInstance: selectedUserInstance));
                      if (result == null) {
                        return;
                      }
                      assert(result is UserInstance);
                      if (result is! UserInstance) {
                        return;
                      }
                      upsertUserInstance(result);
                      // make it default?
                      _selectNewUserInstance(result, makeDefault: true);
                    },
                    icon: const Icon(Icons.edit))
              ],
            );
          }
        );
      }
    );
  }

  void _selectNewUserInstance(UserInstance? result, { bool makeDefault = false }) {
    setState(() {
      selectedUserInstance = result;
    });
    collectionsStream.currentKey = selectedUserInstance?.id;
    if (makeDefault) {
      setDefaultUserInstance(selectedUserInstance?.id);
    }
  }

  Widget _collectionSelection(BuildContext context) {
    return StreamBuilder(
      stream: collectionsStream,
      builder: (context, collections) {
        if (collections.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Error loading user instances: ${collections.error}",
                    style: const TextStyle(color: Colors.red)),
              ],
            ),
          );
        }
        if (collections.connectionState != ConnectionState.active ||
            collections.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Flex(
          direction: Axis.horizontal,
          children: [
            Flexible(
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(
                    labelText: 'Collection',
                  ),
                  value: selectedCollection,
                  items: [
                    for (Collection collection in collections.data ?? [])
                      DropdownMenuItem(
                        value: collection,
                        key: ValueKey(collection.id ?? collection),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  color: collection.color != null
                                      ? colorFromHex(collection.color!)
                                      : const Color(0xff008080),
                                  border: Border.all()
                              ),
                              constraints: const BoxConstraints(
                                maxHeight: 28,
                                maxWidth: 28,
                              ),
                            ),
                            Text(collection.name ?? "Unnamed Collection"),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCollection = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return "Please select a category";
                    }
                    return null;
                  },
                )),
            IconButton(
                onPressed: () async {
                  if (selectedUserInstance?.id != null) {
                    collectionsReplayer.reset(selectedUserInstance!.id);
                  }
                },
                icon: const Icon(Icons.refresh),
            ),
            IconButton(
                onPressed: () async {
                  if (selectedUserInstance?.apiToken == null || selectedUserInstance?.server == null) {
                    return;
                  }
                  var result = await Navigator.pushNamed(
                      context, "collection/new");
                  if (result == null) {
                    return;
                  }
                  assert(result is Collection);
                  if (result is! Collection) {
                    return;
                  }
                  if (selectedUserInstance?.apiToken == null || selectedUserInstance?.server == null) {
                    if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error creating collection')),
                        );
                      }
                      return;
                  }
                  try {
                    Collection? collection = await createCollection(
                        selectedUserInstance!.apiToken!,
                        selectedUserInstance!.server!, result);
                    if (collection == null) {
                      return;
                    }
                    collectionsReplayer.publish(
                        [...collections.data ?? [], collection],
                        currentKey: selectedUserInstance?.id);
                    setState(() {
                      selectedCollection = collection;
                    });
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error creating collection: ${e.toString()}')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add),
            ),
          ],
        );
      }
    );
  }

  List<Widget> _tagsSelection(BuildContext context) {
    return [
      const Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("Tags:"),
        ],
      ),
      Flex(
        direction: Axis.horizontal,
        // crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            children: [
              for (String tag in tags) Chip(label: Text(tag))
            ],
          ),
          IconButton(
              onPressed: () async {
                List<Tag> allTags = [];
                var result = await Navigator.pushNamed(context, "tags/select", arguments: SelectTagsViewArguments(selectedTags: tags, allTags: allTags));
                if (result == null) {
                  return;
                }
                assert(result is List<String>);
                if (result is! List<String>) {
                  return;
                }
                setState(() {
                  tags = result;
                });
              },
              icon: const Icon(Icons.edit))
        ],
      ),
    ];
  }

  Widget _linkInput(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
          labelText: "Link", helper: Text("e.g. http://example.com/")),
      validator: (value) {
        if (value == null) {
          return "Please enter a value";
        }
        Uri? url = Uri.tryParse(value);
        if (url == null) {
          return "Not valid";
        }
        if (!url.isScheme("https") && !url.isScheme("http")) {
          return "Must be http or https";
        }
        return null;
      },
    );
  }

  Widget _nameInput(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
          labelText: "Name",
          helper: Text("Will be auto generated if left empty.")),
    );
  }

  Widget _descriptionInput(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
          labelText: "Description", helper: Text("Notes, thoughts, etc.")),
      maxLines: null,
    );
  }
}
