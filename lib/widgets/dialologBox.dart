import 'package:flutter/material.dart';

class BlackConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final Color confirmColor;

  const BlackConfirmDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.confirmText,
    required this.confirmColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF121212), // Dark black background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Text(
        content,
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText, style: TextStyle(color: confirmColor)),
        ),
      ],
    );
  }
}
