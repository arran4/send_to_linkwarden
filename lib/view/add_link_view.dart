import 'package:flutter/material.dart';
import 'package:linkwarden_mobile/model/collection.dart';
import 'package:linkwarden_mobile/model/tag.dart';
import 'package:linkwarden_mobile/model/user_instance.dart';
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
  late List<Tag> tags;
  UserInstance? selectedUserInstance;
  bool selectedUserInstanceSet = false;
  Collection? selectedCollection;

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
    tags = [Tag(name: "Tag 1"), Tag(name: "Tag 2")];
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
            if (!selectedUserInstanceSet && defaultValueLoaded.requireData != null && selectedUserInstance == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
                selectedUserInstance = list.requireData.where((each) => each.id == defaultValueLoaded.requireData).firstOrNull;
                selectedUserInstanceSet = true;
              }));
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
                    setState(() {
                      selectedUserInstance = value;
                    });
                    setDefaultUserInstance(selectedUserInstance?.id);
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
                      addUserInstances(result);
                      // make it default?
                      setState(() {
                        selectedUserInstance = result;
                      });
                      setDefaultUserInstance(selectedUserInstance?.id);
                    },
                    icon: const Icon(Icons.edit))
              ],
            );
          }
        );
      }
    );
  }

  Widget _collectionSelection(BuildContext context) {
    return Flex(
      direction: Axis.horizontal,
      children: [
        Flexible(
            child: DropdownButtonFormField(
          decoration: const InputDecoration(
            labelText: 'Collection',
          ),
          value: selectedCollection,
          items: const [
            DropdownMenuItem(
              value: null,
              key: ValueKey("Unorganized"),
              child: Text("Unorganized"),
            ),
          ],
          onChanged: (value) {},
        )),
        IconButton(
            onPressed: () async {
              var result = await Navigator.pushNamed(context, "collection/new");
              if (result == null) {
                return;
              }
              assert(result is Collection);
              if (result is! Collection) {
                return;
              }
              // saveCollectionToDataSource;
              // selectedCollect = result;
            },
            icon: const Icon(Icons.add))
      ],
    );
  }

  List<Widget> _tagsSelection(BuildContext context) {
    return [
      const Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("Labels:"),
        ],
      ),
      Flex(
        direction: Axis.horizontal,
        // crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            child: Wrap(
              children: [
                for (Tag tag in tags) Chip(label: Text(tag.name??"Unnamed"))
              ],
            ),
          ),
          IconButton(
              onPressed: () async {
                var result = await Navigator.pushNamed(context, "tags/select", arguments: SelectTagsViewArguments(selectedTags: tags));
                if (result == null) {
                  return;
                }
                assert(result is List<Tag>);
                if (result is! List<Tag>) {
                  return;
                }
                // Save new tags
                // result.where((tag) => tag.id == null);
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
