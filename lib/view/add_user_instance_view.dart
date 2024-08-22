import 'package:flutter/material.dart';

class AddUserInstanceView extends StatefulWidget {
  const AddUserInstanceView({super.key});
  @override
  State<AddUserInstanceView> createState() => _AddUserInstanceViewState();
}

class _AddUserInstanceViewState extends State<AddUserInstanceView> {
  GlobalKey<FormState> formState = GlobalKey<FormState>();

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
              _usernameEmailInput(context),
              _passwordInput(context),
              _actionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _instanceUrlInput(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: "URL",
        hintText: "https://cloud.linkwarden.app",
        helperText: "The address of your Linkwarden instance.",
      ),
    );
  }
  Widget _usernameEmailInput(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: "Username/Email",
        hintText: "Username...",
        helperText: "Username for your Linkwarden Account.",
      ),
    );
  }
  Widget _passwordInput(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: "Password",
        helperText: "Password for your Linkwarden account.",
        hintText: "Password",
      ),
      obscureText: true,
    );
  }
  Widget _actionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(onPressed: () {}, child: const Text("Reset")),
        TextButton(onPressed: () {}, child: const Text("Save")),
      ],
    );
  }
}
