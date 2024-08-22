import 'package:flutter/material.dart';
import 'package:linkwarden_mobile/model/collection.dart';
import 'package:linkwarden_mobile/model/user_instance.dart';
import 'package:linkwarden_mobile/state/dark_mode_notifier.dart';
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
    tags = ["Tag 1", "Tag 2"];
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
            DropdownMenuItem(
              value: UserInstance(user: "User", server: "http://server/"),
              key: const ValueKey("User @ Server"),
              child: const Text("User @ Server"),
            ),
            const DropdownMenuItem(
              value: null,
              key: ValueKey("New"),
              child: Text("New"),
            ),
          ],
          onChanged: (value) {},
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
              // saveUserInstance
              // make it default?
              // selectedUserInstance = result;
            },
            icon: const Icon(Icons.edit))
      ],
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
                for (String tag in tags) Chip(label: Text(tag))
              ],
            ),
          ),
          IconButton(
              onPressed: () async {
                var result = await Navigator.pushNamed(context, "tags/select", arguments: SelectTagsViewArguments(selectedTags: tags));
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
