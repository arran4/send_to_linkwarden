import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:linkwarden_mobile/model/collection.dart';

class AddCollectionViewArguments {
  const AddCollectionViewArguments();
}

class AddCollectionView extends StatefulWidget {
  final AddCollectionViewArguments? arguments;

  const AddCollectionView({super.key, this.arguments});

  @override
  State<AddCollectionView> createState() => _AddCollectionViewState();
}

class _AddCollectionViewState extends State<AddCollectionView> {
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  Color currentColor = const Color(0xff008080);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("New Collection - Linkwarden Mobile"),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: formState,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _collectionNameInput(context),
              _descriptionInput(context),
              ..._colourInput(context),
              _actionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  TextEditingController nameTextController = TextEditingController();
  Widget _collectionNameInput(BuildContext context) {
    return TextFormField(
      controller: nameTextController,
      decoration: const InputDecoration(
        labelText: "Collection Name",
        hintText: "todo, reference, bookmarks, etc",
        helperText: "New collection name.",
      ),
      validator: (input) {
        if (input == null || input == "") {
          return "Please enter a value";
        }
        return null;
      },
    );
  }

  TextEditingController descriptionTextController = TextEditingController();
  Widget _descriptionInput(BuildContext context) {
    return TextFormField(
      controller: descriptionTextController,
      decoration: const InputDecoration(
        labelText: "Description",
        hintText: "The purpose of this Collection...",
      ),
      maxLines: null,
    );
  }

  List<Widget> _colourInput(BuildContext context) {
    return [
      const Row(
        children: [
          Text(
              "Collection Color: "
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: currentColor,
              border: Border.all()
            ),
            constraints: const BoxConstraints(
              maxHeight: 28,
              maxWidth: 140,
            ),
          ),
          TextButton(onPressed: () async {
            var result = await showDialog(
              context: context,
              builder: (context) {
                Color pickerColor = currentColor;
                return AlertDialog(
                  title: const Text('Pick a color!'),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: pickerColor,
                      onColorChanged: (value) {
                        pickerColor = value;
                      },
                    ),
                  ),
                  actions: <Widget>[
                    ElevatedButton(
                      child: const Text('Got it'),
                      onPressed: () {
                        Navigator.of(context).pop(pickerColor);
                      },
                    ),
                  ],
                );
              },
            );
            if (result is Color) {
              setState(() {
                currentColor = result;
              });
            }
          }, child: const Text("Change")),
        ],
      ),
    ];
  }

  Widget _actionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: () {
          if (formState.currentState!.validate()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Processing Data')),
            );
            Navigator.pop(context, Collection()
              ..name = nameTextController.text
              ..description = descriptionTextController.text
              ..color = colorToHex(currentColor, includeHashSign: true, enableAlpha: false, toUpperCase: false)
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
}
