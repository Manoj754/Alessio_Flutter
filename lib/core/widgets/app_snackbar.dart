import 'package:flutter/material.dart';
import 'package:flutterapp/core/util/app_text_style.dart';

/// One way to show a brief, non-blocking message (e.g. a failed refresh while
/// the old list stays on screen).
class AppSnackbar {
  AppSnackbar._();

  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTextStyles.body(color: Colors.white),
          ),
        ),
      );
  }
}
