import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:send_to_linkwarden/model/user_instance.dart';
import 'package:send_to_linkwarden/api/linkwarden.dart';
import 'package:send_to_linkwarden/state/user_instance_replayer.dart';

class AddEditUserInstanceViewArguments {
  final UserInstance? userInstance;

  const AddEditUserInstanceViewArguments({this.userInstance});
}

class AddEditUserInstanceView extends StatefulWidget {
  final AddEditUserInstanceViewArguments? arguments;

  const AddEditUserInstanceView({this.arguments, super.key});

  @override
  State<AddEditUserInstanceView> createState() =>
      _AddEditUserInstanceViewState();
}

class _AddEditUserInstanceViewState extends State<AddEditUserInstanceView> {
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  late UserInstance userInstance;

  String _method = 'apiKey';

  @override
  void initState() {
    super.initState();
    userInstance = widget.arguments?.userInstance ?? UserInstance();

    _loadValues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Instance configuration - Send To Linkwarden"),
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
                  child: StreamBuilder(
                    stream: userInstanceValueReplayer.subscribe(),
                    builder:
                        (context, AsyncSnapshot<List<UserInstance>> snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text("Error: ${snapshot.error}"),
                            );
                          }
                          var instances = snapshot.data ?? [];
                          return Form(
                            key: formState,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                _instanceSelector(context, instances),
                                _instanceUrlInput(context),
                                _methodSelection(context),
                                if (_method == 'apiKey')
                                  _apiTokenInput(context),
                                if (_method == 'username')
                                  _usernameEmailInput(context),
                                if (_method == 'username')
                                  _passwordInput(context),
                                _actionButtons(context),
                              ],
                            ),
                          );
                        },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final TextEditingController urlTextController = TextEditingController();
  Widget _instanceUrlInput(BuildContext context) {
    return TextFormField(
      controller: urlTextController,
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
      decoration: const InputDecoration(
        labelText: "URL",
        hintText: "https://cloud.linkwarden.app",
        helperText: "The address of your Linkwarden instance.",
      ),
    );
  }

  final TextEditingController usernameTextController = TextEditingController();
  Widget _usernameEmailInput(BuildContext context) {
    return TextFormField(
      controller: usernameTextController,
      validator: (value) {
        if (value == null || value == "") {
          return "Please enter a value";
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: "Username/Email",
        hintText: "Username...",
        helperText: "Username for your Linkwarden Account.",
      ),
    );
  }

  Widget _methodSelection(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Authentication Method'),
      initialValue: _method,
      items: const [
        DropdownMenuItem(value: 'apiKey', child: Text('API Key', overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'username', child: Text('Username/Password', overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (value) {
        setState(() {
          _method = value ?? 'apiKey';
        });
      },
    );
  }

  final TextEditingController passwordTextController = TextEditingController();
  Widget _passwordInput(BuildContext context) {
    return TextFormField(
      controller: passwordTextController,
      validator: (value) {
        if (value == null || value == "") {
          return "Please enter a value";
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: "Password",
        helperText: "Password for your Linkwarden account.",
        hintText: "Password",
      ),
      obscureText: true,
    );
  }

  final TextEditingController apiTokenTextController = TextEditingController();
  Widget _apiTokenInput(BuildContext context) {
    return TextFormField(
      controller: apiTokenTextController,
      validator: (value) {
        if (value == null || value == "") {
          return "Please enter a value";
        }
        return null;
      },
      decoration: const InputDecoration(
        labelText: "ApiToken",
        helperText: "ApiToken for your Linkwarden account.",
        hintText: "ApiToken",
      ),
      obscureText: true,
    );
  }

  Widget _actionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            setState(_loadValues);
          },
          child: const Text("Reset"),
        ),
        TextButton(
          onPressed: () async {
            if (formState.currentState!.validate()) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Processing Data')));
              String? token = apiTokenTextController.text;
              if (_method == 'username') {
                try {
                  token = await createSession(
                    urlTextController.text,
                    usernameTextController.text,
                    passwordTextController.text,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login failed: ${e.toString()}')),
                    );
                  }
                  return;
                }
              }

              if (!context.mounted) return;
              Navigator.pop(
                context,
                userInstance
                  ..user = usernameTextController.text
                  ..server = urlTextController.text
                  ..password = _method == 'username'
                      ? passwordTextController.text
                      : null
                  ..apiToken = token,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Validation errors')),
              );
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }

  Widget _instanceSelector(BuildContext context, List<UserInstance> instances) {
    bool editing = instances.any((e) => e.id == userInstance.id);
    return Row(
      children: [
        Expanded(
          child: DropdownButton<UserInstance?>(
            value: editing ? userInstance : null,
            hint: const Text('Select Instance'),
            items: [
              for (var inst in instances)
                DropdownMenuItem(
                  value: inst,
                  child: Text(inst.server ?? 'Unknown URL'),
                ),
              const DropdownMenuItem(value: null, child: Text('New Instance')),
            ],
            onChanged: (value) {
              setState(() {
                userInstance = value ?? UserInstance();

                _loadValues();
              });
            },
          ),
        ),
        if (editing)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Instance'),
                  content: const Text(
                    'Are you sure you want to delete this instance?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await deleteUserInstance(userInstance);
                setState(() {
                  userInstance = UserInstance();

                  _loadValues();
                });
              }
            },
          ),
      ],
    );
  }

  void _loadValues() {
    usernameTextController.text = userInstance.user ?? "";
    urlTextController.text = userInstance.server ?? "";
    passwordTextController.text = userInstance.password ?? "";
    apiTokenTextController.text = userInstance.apiToken ?? "";
    if (userInstance.apiToken != null && userInstance.apiToken!.isNotEmpty) {
      _method = 'apiKey';
    } else {
      _method = 'username';
    }
    // Determine if we are editing an existing instance based on stored list
    unawaited(
      userInstanceValueReplayer.subscribe().first.then((list) {
        if (!mounted) {
          return;
        }
        setState(() {});
      }),
    );
  }
}
