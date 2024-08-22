import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SelectTagsView extends StatefulWidget {
  const SelectTagsView({super.key});

  @override
  State<SelectTagsView> createState() => _SelectTagsViewState();
}

class _SelectTagsViewState extends State<SelectTagsView> {
  List<String> allTags = [
    "Tag 1",
    "Tag 2",
    "Tag 3",
    "Tag 4",
    "Tag 5",
    "Tag 6",
  ];
  late Set<String> selectedTags;
  final TextEditingController searchAddTextController = TextEditingController();
  late String filterText;

  @override
  void initState() {
    super.initState();
    selectedTags = {"Tag 1", "Tag 3"};
    filterText = "";
    searchAddTextController.addListener(() {
      setState(() {
        filterText = searchAddTextController.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Select Tags - Linkwarden Mobile"),
        actions: [IconButton(onPressed: () {
          Navigator.pop(context, selectedTags.toList());
        }, icon: const Icon(Icons.check))],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _findOrAddWidget(context),
            _listOfElements(context),
          ],
        ),
      ),
    );
  }

  Widget _findOrAddWidget(BuildContext builder) {
    return TextField(
      decoration: InputDecoration(
        labelText: "Tag Name",
        helperText: "Filter or add",
        hintText: "...",
        suffix: IconButton(onPressed: () { add(searchAddTextController.text); }, icon: const Icon(Icons.add)),
      ),
      controller: searchAddTextController,
      onSubmitted: (value) => add(value),
    );
  }

  List<String> get filteredTags {
    if (filterText == "") {
      return allTags;
    } else {
      return allTags.where((element) => element.contains(filterText)).toList();
    }
  }

  Widget _listOfElements(BuildContext context) {
    return ListBody(
      children: [
        for (String tag in filteredTags)
          ListTile(
            key: ValueKey(tag),
            leading: Checkbox(
                value: selectedTags.contains(tag),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    if (selectedTags.contains(tag)) {
                      selectedTags.remove(tag);
                    } else {
                      selectedTags.add(tag);
                    }
                  });
                }),
            title: Text(tag),
          ),
      ],
    );
  }

  void add(String text) {
    var trimmed = text.trim();
    if (trimmed == "") {
      return;
    }
    if (allTags.contains(trimmed)) {
      return;
    }
    setState(() {
      allTags.add(trimmed);
      selectedTags.add(trimmed);
      searchAddTextController.clear();
    });
  }
}
