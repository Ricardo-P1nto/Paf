import 'package:flutter/material.dart';

void mostarSnackBar({
  required BuildContext context,
  required String mensagem,
  bool erro = true,
}) {
  final snackBar = SnackBar(
    content: Text(mensagem),
    backgroundColor: erro ? Colors.red.shade900 : Colors.green.shade900,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    margin: const EdgeInsets.only(
      bottom: 10, // Add space between the SnackBar and the bottom of the screen
      left: 10,
      right: 10,
    ),
    duration: const Duration(seconds: 3),
    action: SnackBarAction(
      label: 'OK',
      textColor: Colors.white,
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
