import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:send_to_linkwarden/api/linkwarden.dart';
import 'package:send_to_linkwarden/core/individual_keyed_pub_sub_replay.dart';
import 'package:send_to_linkwarden/model/collection.dart';
import 'package:send_to_linkwarden/model/link.dart';
import 'package:send_to_linkwarden/model/tag.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/state/collections_replayer.dart';
import 'package:send_to_linkwarden/state/dark_mode_notifier.dart';
import 'package:send_to_linkwarden/state/default_user_instance.dart';
import 'package:send_to_linkwarden/state/tags_replayer.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';
import 'package:send_to_linkwarden/view/select_tags_view.dart';
import 'package:send_to_linkwarden/view/main_drawer.dart';
import 'package:collection/collection.dart';

import 'add_edit_user_instance_view.dart';

class AddLinkViewArguments {
  final String? link;
  final String? name;
  final String? description;

  AddLinkViewArguments({this.link, this.name, this.description});
}

class AddLinkView extends StatefulWidget {
  final AddLinkViewArguments? arguments;
  final Future<Map<String, String?>> Function(String url)? fetchPreviewOverride;
  final Future<Link?> Function(String token, String baseUrl, Link link)?
  postLinkOverride;
  final IndividualKeyedPubSubReplay<String?, List<Collection>?>?
  collectionsReplayerOverride;
  final IndividualKeyedPubSubReplay<String?, List<Tag>?>? tagsReplayerOverride;
  final Future<String?> Function()? loadDefaultUserInstanceOverride;

  const AddLinkView({
    super.key,
    this.arguments,
    this.fetchPreviewOverride,
    this.postLinkOverride,
    this.collectionsReplayerOverride,
    this.tagsReplayerOverride,
    this.loadDefaultUserInstanceOverride,
  });

  @override
  State<AddLinkView> createState() => _AddLinkViewState();
}

enum _SubmitState { idle, submitting, success, error }

class _AddLinkViewState extends State<AddLinkView> {
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  late List<String> tags;
  UserInstance? selectedUserInstance;
  bool selectedUserInstanceSet = false;
  Collection? selectedCollection;
  late IndividualKeyedPubSubReplayStream<String?, List<Collection>?>
  collectionsStream;
  TextEditingController nameTextController = TextEditingController();
  TextEditingController descriptionTextController = TextEditingController();
  TextEditingController linkTextController = TextEditingController();
  String? previewImageUrl;
  bool previewLoading = false;
  bool previewError = false;
  _SubmitState _submitState = _SubmitState.idle;
  String? _submitError;

  Future<void> _fetchPreview() async {
    setState(() {
      previewLoading = true;
      previewError = false;
    });
    try {
      final fetch = widget.fetchPreviewOverride ?? fetchPreview;
      final preview = await fetch(linkTextController.text);
      if (preview['title'] != null && nameTextController.text.isEmpty) {
        nameTextController.text = preview['title']!;
      }
      if (preview['description'] != null &&
          descriptionTextController.text.isEmpty) {
        descriptionTextController.text = preview['description']!;
      }
      setState(() {
        previewImageUrl = preview['image'];
        previewLoading = false;
      });
    } catch (_) {
      setState(() {
        previewLoading = false;
        previewError = true;
        previewImageUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Add Bookmark - Send To Linkwarden"),
        actions: [
          IconButton(
            onPressed: () {
              unawaited(_darkMode());
            },
            icon: const Icon(Icons.dark_mode),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: formState,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _userAndInstanceSelection(context),
                        _collectionSelection(context),
                        _linkInput(context),
                        _previewCard(),
                        ..._tagsSelection(context),
                        _nameInput(context),
                        _descriptionInput(context),
                        _submitButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    tags = [];
    final cReplayer = widget.collectionsReplayerOverride ?? collectionsReplayer;
    collectionsStream = cReplayer.subscribe(initialKey: null);
    if (widget.arguments?.link != null) {
      linkTextController.text = widget.arguments!.link!;
      unawaited(_fetchPreview());
    }
    if (widget.arguments?.name != null) {
      nameTextController.text = widget.arguments!.name!;
    }
    if (widget.arguments?.description != null) {
      descriptionTextController.text = widget.arguments!.description!;
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_promptForInstanceIfNeeded()),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _darkMode() async {
    await setDarkMode(!darkModeNotifier.value);
  }

  Future<void> _promptForInstanceIfNeeded() async {
    var list = await userInstanceValueReplayer.subscribe().first;
    if (!mounted) return;
    if (list.isEmpty) {
      var result = await Navigator.pushNamed(
        context,
        'userInstance/newEdit',
        arguments: const AddEditUserInstanceViewArguments(),
      );
      if (result is UserInstance) {
        upsertUserInstance(result);
        _selectNewUserInstance(result, makeDefault: true);
      }
    }
  }

  Widget _submitButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          if (_submitState == _SubmitState.error)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                _submitError ?? 'An error occurred',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          FilledButton(
            onPressed: _submitState == _SubmitState.submitting ? null : _submit,
            child: _submitState == _SubmitState.submitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!formState.currentState!.validate()) {
      return;
    }

    if (selectedUserInstance?.apiToken == null ||
        selectedUserInstance?.server == null) {
      setState(() {
        _submitState = _SubmitState.error;
        _submitError = "Please select a valid user instance.";
      });
      return;
    }

    setState(() {
      _submitState = _SubmitState.submitting;
      _submitError = null;
    });

    List<Tag>? allTags;
    try {
      final tReplayer = widget.tagsReplayerOverride ?? tagsReplayer;
      allTags = await tReplayer
          .subscribe(initialKey: selectedUserInstance!.id)
          .first;
    } catch (_) {
      // ignore
    }
    Map<String, Tag> tagLookup = Map<String, Tag>.fromIterable(
      allTags ?? [],
      key: (element) => element.name ?? "Untitled",
    );
    Link? result;
    try {
      final submitLink = widget.postLinkOverride ?? postLink;
      result = await submitLink(
        selectedUserInstance!.apiToken!,
        selectedUserInstance!.server!,
        Link(
          name: nameTextController.text,
          description: descriptionTextController.text,
          url: linkTextController.text,
          collection: selectedCollection,
          tags: tags.map((tagName) {
            if (tagLookup.containsKey(tagName) && tagLookup[tagName] != null) {
              return tagLookup[tagName]!;
            }
            return Tag(name: tagName);
          }).toList(),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitState = _SubmitState.error;
        _submitError =
            "Failed to submit link. Please check your connection and try again.";
      });
      return;
    }

    if (!mounted) {
      return;
    }

    if (result == null) {
      setState(() {
        _submitState = _SubmitState.error;
        _submitError =
            "Failed to submit link. Please check your connection and try again.";
      });
      return;
    }

    setState(() {
      _submitState = _SubmitState.success;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bookmark saved!')));

    _resetForm();

    if (widget.arguments != null) {
      Navigator.pop(context, result);
    }

    // reset success state after a short delay so user sees form again
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _submitState = _SubmitState.idle;
        });
      }
    });
  }

  void _resetForm() {
    formState.currentState?.reset();
    linkTextController.text = "";
    nameTextController.text = "";
    descriptionTextController.text = "";
    previewImageUrl = null;
    setState(() {
      tags = [];
    });
  }

  Widget _userAndInstanceSelection(BuildContext context) {
    final loadDef =
        widget.loadDefaultUserInstanceOverride ?? loadDefaultUserInstance;
    return FutureBuilder(
      future: loadDef(),
      builder: (context, defaultValueLoaded) {
        if (defaultValueLoaded.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Error loading default user instance: ${defaultValueLoaded.error}",
                  style: const TextStyle(color: Colors.red),
                ),
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
                    Text(
                      "Error loading user instances: ${list.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              );
            }
            if (list.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!selectedUserInstanceSet &&
                list.connectionState == ConnectionState.active) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  selectedUserInstanceSet = true;
                });
                UserInstance? chosen;
                if (defaultValueLoaded.data != null) {
                  chosen = list.requireData.firstWhereOrNull(
                    (each) => each.id == defaultValueLoaded.requireData,
                  );
                  chosen ??= list.requireData.isNotEmpty
                      ? list.requireData.first
                      : null;
                } else if (list.requireData.isNotEmpty) {
                  chosen = list.requireData.first;
                }
                _selectNewUserInstance(chosen, makeDefault: false);
              });
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
                    initialValue: selectedUserInstance,
                    items: [
                      for (UserInstance ui in list.data ?? [])
                        DropdownMenuItem(
                          value: ui,
                          key: ValueKey(ui.id),
                          child: Text(ui.server ?? "Unknown URL"),
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
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    var result = await Navigator.pushNamed(
                      context,
                      "userInstance/newEdit",
                      arguments: AddEditUserInstanceViewArguments(
                        userInstance: selectedUserInstance,
                      ),
                    );
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
                  icon: const Icon(Icons.edit),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _selectNewUserInstance(
    UserInstance? result, {
    bool makeDefault = false,
  }) {
    if (selectedUserInstance?.id != result?.id) {
      setState(() {
        selectedCollection = null;
        tags = [];
      });
    }
    setState(() {
      selectedUserInstance = result;
    });
    collectionsStream.currentKey = selectedUserInstance?.id;
    if (makeDefault) {
      unawaited(setDefaultUserInstance(selectedUserInstance?.id));
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
                Text(
                  "Error loading user instances: ${collections.error}",
                  style: const TextStyle(color: Colors.red),
                ),
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
                decoration: const InputDecoration(labelText: 'Collection'),
                initialValue: selectedCollection,
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
                              border: Border.all(),
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
              ),
            ),
            IconButton(
              onPressed: () async {
                if (selectedUserInstance?.id != null) {
                  final cReplayer =
                      widget.collectionsReplayerOverride ?? collectionsReplayer;
                  cReplayer.reset(selectedUserInstance!.id);
                }
              },
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () async {
                if (selectedUserInstance?.apiToken == null ||
                    selectedUserInstance?.server == null) {
                  return;
                }
                var result = await Navigator.pushNamed(
                  context,
                  "collection/new",
                );
                if (result == null) {
                  return;
                }
                assert(result is Collection);
                if (result is! Collection) {
                  return;
                }
                if (selectedUserInstance?.apiToken == null ||
                    selectedUserInstance?.server == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error creating collection'),
                      ),
                    );
                  }
                  return;
                }
                try {
                  Collection? collection = await createCollection(
                    selectedUserInstance!.apiToken!,
                    selectedUserInstance!.server!,
                    result,
                  );
                  if (collection == null) {
                    return;
                  }
                  final cReplayer =
                      widget.collectionsReplayerOverride ?? collectionsReplayer;
                  cReplayer.publish([
                    ...collections.data ?? [],
                    collection,
                  ], currentKey: selectedUserInstance?.id);
                  setState(() {
                    selectedCollection = collection;
                  });
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error creating collection: ${e.toString()}',
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _tagsSelection(BuildContext context) {
    return [
      const Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [Text("Tags:")],
      ),
      Flex(
        direction: Axis.horizontal,
        // crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(children: [for (String tag in tags) Chip(label: Text(tag))]),
          IconButton(
            onPressed: () async {
              var result = await Navigator.pushNamed(
                context,
                "tags/select",
                arguments: SelectTagsViewArguments(
                  selectedTags: tags,
                  userInstance: selectedUserInstance,
                ),
              );
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
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
    ];
  }

  Widget _linkInput(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Link",
        helper: const Text("e.g. http://example.com/"),
        suffixIcon: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            unawaited(_fetchPreview());
          },
        ),
      ),
      onEditingComplete: () {
        unawaited(_fetchPreview());
      },
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
        labelText: "Description",
        helper: Text("Notes, thoughts, etc."),
      ),
      maxLines: null,
      controller: descriptionTextController,
    );
  }

  Widget _previewCard() {
    if (previewLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: CircularProgressIndicator(),
      );
    }
    if (previewError) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          "Could not load preview",
          style: TextStyle(color: Colors.red),
        ),
      );
    }
    if (previewImageUrl == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Image.network(
        previewImageUrl!,
        height: 100,
        errorBuilder: (context, error, stackTrace) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Failed to load image",
              style: TextStyle(color: Colors.red),
            ),
          );
        },
      ),
    );
  }
}
