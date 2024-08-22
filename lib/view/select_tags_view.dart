import 'dart:async';

import 'package:flutter/material.dart';
import 'package:linkwarden_mobile/core/individual_keyed_pub_sub_replay.dart';
import 'package:linkwarden_mobile/model/tag.dart';
import 'package:linkwarden_mobile/model/user_instance.dart';
import 'package:linkwarden_mobile/state/tags_replayer.dart';

class SelectTagsViewArguments {
  final List<String>? selectedTags;
  final List<Tag>? allTags;
  final UserInstance? userInstance;

  const SelectTagsViewArguments({
    this.selectedTags,
    this.allTags,
    this.userInstance,
  });
}

class SelectTagsView extends StatefulWidget {
  final SelectTagsViewArguments? arguments;
  
  const SelectTagsView({super.key, this.arguments});

  @override
  State<SelectTagsView> createState() => _SelectTagsViewState();
}

class _SelectTagsViewState extends State<SelectTagsView> {
  List<Tag>? allTags;
  late Set<String> selectedTags;
  final TextEditingController searchAddTextController = TextEditingController();
  late String filterText;
  StreamSubscription<List<Tag>?>? tagSubscription;

  FocusNode findOrAddFocusNode = FocusNode();

  UserInstance? get userInstance {
    return widget.arguments?.userInstance;
  }

  @override
  void initState() {
    super.initState();
    selectedTags = Set.from(widget.arguments?.selectedTags??[]);
    filterText = "";
    searchAddTextController.addListener(() {
      setState(() {
        filterText = searchAddTextController.text;
      });
    });

    if (widget.arguments?.allTags != null) {
      allTags = [...widget.arguments!.allTags!];
      addNewTags();
      sortTags();
    } else if (userInstance?.valid == true) {
      var tagStream = tagsReplayer.subscribe(initialKey: userInstance!.id);
      tagSubscription = tagStream.listen((List<Tag>? event) {
        setState(() {
          allTags = [...event??[]];
          addNewTags();
          sortTags();
        });
      });
    } else {
      allTags = [];
      addNewTags();
      sortTags();
    }
  }

  void sortTags() {
    allTags?.sort((Tag a, Tag b) {
      var containsA = selectedTags.contains(a.name);
      var containsB = selectedTags.contains(b.name);
      if (containsA && !containsB) {
        return -1;
      }
      if (!containsA && containsB) {
        return 1;
      }
      return (a.name??"").compareTo(b.name??"");
    });
  }

  void addNewTags() {
    Map<String, Tag> hasTag = Map<String, Tag>.fromIterable(allTags??[],key: (element) => element.name??"Untitled",);
    for (String tag in selectedTags) {
      if (!hasTag.containsKey(tag)) {
        allTags?.add(Tag(name: tag));
      }
    }
  }

  @override
  void dispose() {
    tagSubscription?.cancel();
    super.dispose();
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
        suffix: IconButton(onPressed: () {
          add(searchAddTextController.text);
          searchAddTextController.clear();
          findOrAddFocusNode.requestFocus();
        },
            icon: const Icon(Icons.add),
        ),
      ),
      focusNode: findOrAddFocusNode,
      controller: searchAddTextController,
      onSubmitted: (value) {
        add(value);
        searchAddTextController.clear();
        findOrAddFocusNode.requestFocus();
      },
    );
  }

  List<Tag> get filteredTags {
    if (filterText == "") {
      return allTags??[];
    } else {
      return (allTags??[]).where((element) => element.name?.contains(filterText)??false).toList();
    }
  }

  Widget _listOfElements(BuildContext context) {
    if (allTags == null) {
      return const CircularProgressIndicator();
    }
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
                    sortTags();
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
    Tag? search = List<Tag?>.from(allTags??[]).firstWhere((t) => t?.name?.contains(trimmed) ?? false, orElse: () => null);
    if (search != null) {
      setState(() {
        if (selectedTags.contains(trimmed)) {
          selectedTags.remove(trimmed);
        } else {
          selectedTags.add(trimmed);
        }
        sortTags();
      });
      return;
    }
    Tag tag = Tag(
      name: trimmed,
    );
    setState(() {
      allTags?.add(tag);
      selectedTags.add(trimmed);
      sortTags();
    });
  }
}
