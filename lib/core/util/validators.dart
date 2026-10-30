/// Lightweight, shared input validation so forms give instant feedback instead
/// of a server round-trip. Each returns the user-facing problem, or null when
/// the value is fine — the shape `TextFormField.validator` expects.
library;

import 'package:flutterapp/core/localization/app_strings.dart';

String? usernameProblem(String? value) {
  if (value == null || value.trim().isEmpty) return AppStrings.usernameRequired;
  return null;
}

String? passwordProblem(String? value) {
  if (value == null || value.isEmpty) return AppStrings.passwordRequired;
  return null;
}
