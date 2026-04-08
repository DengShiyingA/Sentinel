import 'package:flutter/material.dart';

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Flexible(child: Text(message)),
    ]),
    backgroundColor: Colors.green,
    duration: const Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
  ));
}

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.error_outline, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Flexible(child: Text(message)),
    ]),
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 3),
    behavior: SnackBarBehavior.floating,
    action: SnackBarAction(label: '关闭', textColor: Colors.white, onPressed: () {}),
  ));
}

void showInfo(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: color,
    duration: const Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
  ));
}
