import 'package:flutter/material.dart';
import 'package:linkwarden_mobile/model/tag.dart';

class SelectTagsViewArguments {
  final List<Tag>? selectedTags;

  const SelectTagsViewArguments({
    this.selectedTags,
  });
}

class SelectTagsView extends StatefulWidget {
  final SelectTagsViewArguments? arguments;
  
  const SelectTagsView({super.key, this.arguments});

  @override
  State<SelectTagsView> createState() => _SelectTagsViewState();
}

class _SelectTagsViewState extends State<SelectTagsView> {
  List<Tag> allTags = [
    Tag(name: "Tag 1"),
    Tag(name: "Tag 2"),
    Tag(name: "Tag 3"),
    Tag(name: "Tag 4"),
    Tag(name: "Tag 5"),
    Tag(name: "Tag 6"),
  ];
  late Set<Tag> selectedTags;
  final TextEditingController searchAddTextController = TextEditingController();
  late String filterText;

  @override
  void initState() {
    super.initState();
    selectedTags = Set.from(widget.arguments?.selectedTags??[]);
    Set<Tag> hasTag = Set.from(allTags);
    for (Tag tag in selectedTags) {
      if (!hasTag.contains(tag)) {
        allTags.add(tag);
      }
    }
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

  List<Tag> get filteredTags {
    if (filterText == "") {
      return allTags;
    } else {
      return allTags.where((element) => element.name?.contains(filterText)??false).toList();
    }
  }

  Widget _listOfElements(BuildContext context) {
    return ListBody(
      children: [
        for (Tag tag in filteredTags)
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
            title: Text(tag.name??"Unnamed Tag"),
          ),
      ],
    );
  }

  void add(String text) {
    var trimmed = text.trim();
    if (trimmed == "") {
      return;
    }
    Tag? search = List<Tag?>.from(allTags).firstWhere((t) => t?.name?.contains(trimmed) ?? false, orElse: () => null);
    if (search != null) {
      selectedTags.add(search);
      return;
    }
    Tag tag = Tag(
      name: trimmed,
    );
    setState(() {
      allTags.add(tag);
      selectedTags.add(tag);
      searchAddTextController.clear();
    });
  }
}
