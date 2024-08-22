import 'package:flutter/material.dart';
import 'package:linkwarden_mobile/state/dark_mode_notifier.dart';

class AddLinkView extends StatefulWidget {
  const AddLinkView({super.key});

  @override
  State<AddLinkView> createState() => _AddLinkViewState();
}

class _AddLinkViewState extends State<AddLinkView> {
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  late List<String> tags;

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
            return "Not valid";
          },
          items: const [
            DropdownMenuItem(
              value: "User @ Server",
              key: ValueKey("User @ Server"),
              child: Text("User @ Server"),
            ),
            DropdownMenuItem(
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
                  await Navigator.pushNamed(context, "userInstance/new");
              if (result == null) {
                return;
              }
              assert(result is String);
              if (result is! String) {
                return;
              }
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
          validator: (value) {
            return "Not valid";
          },
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
              assert(result is String);
              if (result is! String) {
                return;
              }
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
                var result = await Navigator.pushNamed(context, "tags/select");
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
      validator: (input) {
        return "Not Valid";
      },
    );
  }

  Widget _nameInput(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
          labelText: "Name",
          helper: Text("Will be auto generated if left empty.")),
      validator: (input) {
        return "Not Valid";
      },
    );
  }

  Widget _descriptionInput(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
          labelText: "Description", helper: Text("Notes, thoughts, etc.")),
      maxLines: null,
      validator: (input) {
        return "Not Valid";
      },
    );
  }
}
