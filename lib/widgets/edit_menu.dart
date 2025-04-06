import 'package:argent/components/tags.dart';
import 'package:flutter/material.dart';

/// This widget displays a menu to edit a transaction
class EditMenuWidget extends StatefulWidget {
  const EditMenuWidget({super.key});

  @override
  State<EditMenuWidget> createState() => EditMenuWidgetState();
}

class EditMenuWidgetState extends State<EditMenuWidget> {
  /// User selected tag
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add a tag"),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Tag Transaction: "),
          DropdownButton(
            value: _selectedTag,
            hint: Text('Select a tag'),
            items: Tags().getAllTags().map((String tag) {
                return DropdownMenuItem(value: tag, child: Text(tag));
              }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                if (newValue != null) {
                  _selectedTag = newValue;
                }
              });
            },
          ),
          IconButton(
            onPressed: () {
              setState(() {
                // return special string to delete all tags from transaction
                Navigator.of(context).pop(Tags().delete);
              });
            },
            icon: const Icon(Icons.delete_outline)
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedTag);
          },
          child: const Text('Close')
        )
      ],
    );
  }
}