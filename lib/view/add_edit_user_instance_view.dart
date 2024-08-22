import 'package:flutter/material.dart';
import 'package:linkwarden_mobile/model/user_instance.dart';

class AddEditUserInstanceViewArguments {
  final UserInstance? userInstance;

  const AddEditUserInstanceViewArguments({
    this.userInstance,
  });
}

class AddEditUserInstanceView extends StatefulWidget {
  final AddEditUserInstanceViewArguments? arguments;

  const AddEditUserInstanceView({this.arguments, super.key});

  @override
  State<AddEditUserInstanceView> createState() => _AddEditUserInstanceViewState();
}

class _AddEditUserInstanceViewState extends State<AddEditUserInstanceView> {
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  late UserInstance userInstance;

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
        title: const Text("Instance configuration - Linkwarden Mobile"),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: formState,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _instanceUrlInput(context),
              _apiTokenInput(context),
              // _usernameEmailInput(context),
              // _passwordInput(context),
              _actionButtons(context),
            ],
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
        TextButton(onPressed: () {
          setState(_loadValues);
        }, child: const Text("Reset")),
        TextButton(onPressed: () {
          if (formState.currentState!.validate()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Processing Data')),
            );
            Navigator.pop(context, userInstance
              ..user = usernameTextController.text
              ..server = urlTextController.text
              ..password = passwordTextController.text
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Validation errors')),
            );
          }
        }, child: const Text("Save")),
      ],
    );
  }

  void _loadValues() {
    usernameTextController.text = userInstance.user ?? "";
    urlTextController.text = userInstance.server ?? "";
    passwordTextController.text = userInstance.password ?? "";
    apiTokenTextController.text = userInstance.apiToken ?? "";
  }
}
