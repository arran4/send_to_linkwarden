import 'dart:async';

import 'package:flutter/material.dart';

import 'package:send_to_linkwarden/model/tag.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/state/tags_replayer.dart';

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
    selectedTags = Set.from(widget.arguments?.selectedTags ?? []);
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
          allTags = [...event ?? []];
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
      return (a.name ?? "").compareTo(b.name ?? "");
    });
  }

  void addNewTags() {
    Map<String, Tag> hasTag = Map<String, Tag>.fromIterable(
      allTags ?? [],
      key: (element) => element.name ?? "Untitled",
    );
    for (String tag in selectedTags) {
      if (!hasTag.containsKey(tag)) {
        allTags?.add(Tag(name: tag));
      }
    }
  }

  @override
  void dispose() {
    final subscription = tagSubscription;
    tagSubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Select Tags - Send To Linkwarden"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context, selectedTags.toList());
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _findOrAddWidget(context),
                      Flexible(child: _listOfElements(context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
        suffix: IconButton(
          onPressed: () {
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
      return allTags ?? [];
    } else {
      final query = filterText.toLowerCase();
      return (allTags ?? [])
          .where(
            (element) => element.name?.toLowerCase().contains(query) ?? false,
          )
          .toList();
    }
  }

  Widget _listOfElements(BuildContext context) {
    if (allTags == null) {
      return const CircularProgressIndicator();
    }

    final tagsToShow = filteredTags;
    final trimmedFilter = filterText.trim();

    bool showCreateOption = false;
    if (trimmedFilter.isNotEmpty) {
      final exactMatchExists = allTags!.any(
        (t) => t.name?.toLowerCase() == trimmedFilter.toLowerCase(),
      );
      if (!exactMatchExists) {
        showCreateOption = true;
      }
    }

    if (tagsToShow.isEmpty && !showCreateOption) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("No tags found"),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: tagsToShow.length + (showCreateOption ? 1 : 0),
      itemBuilder: (context, index) {
        if (showCreateOption && index == tagsToShow.length) {
          return ListTile(
            key: const ValueKey("create_new_tag"),
            leading: const Icon(Icons.add),
            title: Text("Create tag '$trimmedFilter'"),
            onTap: () {
              add(trimmedFilter);
              searchAddTextController.clear();
              findOrAddFocusNode.requestFocus();
            },
          );
        }

        final tag = tagsToShow[index];
        final String tagName = tag.name ?? "Untitled Tag";
        final bool isSelected = selectedTags.contains(tagName);

        return ListTile(
          key: ValueKey(tag),
          leading: Checkbox(
            value: isSelected,
            onChanged: (value) {
              if (value == null) return;
              _toggleSelection(tagName);
            },
          ),
          title: Text(tagName),
          onTap: () => _toggleSelection(tagName),
        );
      },
    );
  }

  void _toggleSelection(String tagName) {
    setState(() {
      if (selectedTags.contains(tagName)) {
        selectedTags.remove(tagName);
      } else {
        selectedTags.add(tagName);
      }
      sortTags();
    });
  }

  void add(String text) {
    var trimmed = text.trim();
    if (trimmed == "") {
      return;
    }
    Tag? search = List<Tag?>.from(allTags ?? []).firstWhere(
      (t) => t?.name?.toLowerCase() == trimmed.toLowerCase(),
      orElse: () => null,
    );
    if (search != null && search.name != null) {
      _toggleSelection(search.name!);
      return;
    }
    Tag tag = Tag(name: trimmed);
    setState(() {
      allTags?.add(tag);
      selectedTags.add(trimmed);
      sortTags();
    });
  }
}
