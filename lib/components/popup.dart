import 'package:flutter/material.dart';

/// Creates an error pop up dialogue
Future<bool> showErrorDialogue(String message, BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ok'),
          )
        ],
      );
    }
  ) ?? false;
}

/// Creates a confirmation pop up
Future<bool> showConfirmationDialogue(String title,
                                    String message,
                                    BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Yes'),
          ),
        ],
      );
    }) ?? false;
}