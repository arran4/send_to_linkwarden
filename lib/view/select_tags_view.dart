import 'package:flutter/material.dart';
import 'package:linkwarden_mobile/model/tag.dart';

class SelectTagsViewArguments {
  final List<String>? selectedTags;
  final List<Tag>? allTags;

  const SelectTagsViewArguments({
    this.selectedTags,
    this.allTags,
  });
}

class SelectTagsView extends StatefulWidget {
  final SelectTagsViewArguments? arguments;
  
  const SelectTagsView({super.key, this.arguments});

  @override
  State<SelectTagsView> createState() => _SelectTagsViewState();
}

class _SelectTagsViewState extends State<SelectTagsView> {
  late List<Tag> allTags;
  late Set<String> selectedTags;
  final TextEditingController searchAddTextController = TextEditingController();
  late String filterText;

  @override
  void initState() {
    super.initState();
    allTags = [...widget.arguments?.allTags??[]];
    selectedTags = Set.from(widget.arguments?.selectedTags??[]);
    Map<String, Tag> hasTag = Map<String, Tag>.fromIterable(allTags,key: (element) => element.name??"Untitled",);
    for (String tag in selectedTags) {
      if (!hasTag.containsKey(tag)) {
        allTags.add(Tag(name: tag));
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
                value: selectedTags.contains(tag.name??"Untitled Tag"),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    String tagName = tag.name??"Untitled Tag";
                    if (selectedTags.contains(tagName)) {
                      selectedTags.remove(tagName);
                    } else {
                      selectedTags.add(tagName);
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
      selectedTags.add(trimmed);
      return;
    }
    Tag tag = Tag(
      name: trimmed,
    );
    setState(() {
      allTags.add(tag);
      selectedTags.add(trimmed);
      searchAddTextController.clear();
    });
  }
}
