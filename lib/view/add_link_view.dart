import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:linkwarden_mobile/api/linkwarden.dart';
import 'package:linkwarden_mobile/core/individual_keyed_pub_sub_replay.dart';
import 'package:linkwarden_mobile/model/collection.dart';
import 'package:linkwarden_mobile/model/link.dart';
import 'package:linkwarden_mobile/model/tag.dart';
import 'package:linkwarden_mobile/model/user_instance.dart';
import 'package:linkwarden_mobile/state/collections_replayer.dart';
import 'package:linkwarden_mobile/state/dark_mode_notifier.dart';
import 'package:linkwarden_mobile/state/default_user_instance.dart';
import 'package:linkwarden_mobile/state/tags_replayer.dart';
import 'package:linkwarden_mobile/state/user_instance_replayer.dart';
import 'package:linkwarden_mobile/view/select_tags_view.dart';

import 'add_edit_user_instance_view.dart';

class AddLinkViewArguments {
  final String? link;
  final String? name;
  final String? description;

  AddLinkViewArguments({this.link, this.name, this.description});
}

class AddLinkView extends StatefulWidget {
  final AddLinkViewArguments? arguments;
  const AddLinkView({super.key, this.arguments });

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
  TextEditingController nameTextController = TextEditingController();
  TextEditingController descriptionTextController = TextEditingController();
  TextEditingController linkTextController = TextEditingController();

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
    if (widget.arguments?.link != null) {
      linkTextController.text = widget.arguments!.link!;
    }
    if (widget.arguments?.name != null) {
      nameTextController.text = widget.arguments!.name!;
    }
    if (widget.arguments?.description != null) {
      descriptionTextController.text = widget.arguments!.description!;
    }
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
        onPressed: () async {
          if (!formState.currentState!.validate()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Validation errors')),
            );
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Submitting Link')),
          );
          List<Tag>? allTags = await tagsReplayer.subscribe(initialKey: selectedUserInstance!.id).first;
          Map<String, Tag> tagLookup = Map<String, Tag>.fromIterable(allTags??[],key: (element) => element.name??"Untitled",);
          Link? result;
          try {
            result = await postLink(
                selectedUserInstance!.apiToken!,
                selectedUserInstance!.server!,
                Link(
                    name: nameTextController.text,
                    description: descriptionTextController.text,
                    url: linkTextController.text,
                    collection: selectedCollection,
                    tags: tags.map((tagName) {
                      if (tagLookup.containsKey(tagName) &&
                          tagLookup[tagName] != null) {
                        return tagLookup[tagName]!;
                      }
                      return Tag(name: tagName);
                    }).toList()));
          } catch (e) {
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error submitting link ${e.toString()}')),
            );
            return;
          }
          _resetForm();
          if (!context.mounted) {
            return;
          }
          if (result == null) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Link ${result.id} created')),
          );
          if (widget.arguments != null) {
            Navigator.pop(context, result);
          }
          return;
        },
        child: const Text('Submit'),
      ),
    );
  }

  void _resetForm() {
    formState.currentState?.reset();
    linkTextController.text = "";
    nameTextController.text = "";
    descriptionTextController.text = "";
    setState(() {
      tags = [];
    });
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
                    if (!value.valid) {
                      return "Instance details lack either a URL or a ApiToken";
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
                var result = await Navigator.pushNamed(context, "tags/select", arguments: SelectTagsViewArguments(selectedTags: tags, userInstance: selectedUserInstance));
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
      controller: linkTextController,
    );
  }

  Widget _nameInput(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
          labelText: "Name",
          helper: Text("Will be auto generated if left empty."),
      ),
      controller: nameTextController,
    );
  }

  Widget _descriptionInput(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
          labelText: "Description", helper: Text("Notes, thoughts, etc.")),
      maxLines: null,
      controller: descriptionTextController,
    );
  }
}
