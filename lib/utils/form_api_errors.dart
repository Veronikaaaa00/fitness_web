import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';

/// 422 → поля формы; остальное → SnackBar. Возвращает false при ошибке.
Future<bool> handleFormApiError(
  BuildContext context, {
  required Object error,
  required void Function(Map<String, String> fieldErrors) onValidation,
}) async {
  if (error is ValidationException) {
    onValidation(error.fields);
    if (context.mounted && error.fields.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
    return false;
  }
  if (error is ApiException) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
    return false;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizeApiMessage('$error'))),
    );
  }
  return false;
}

String? serverFieldError(Map<String, String> errors, List<String> keys) {
  for (final k in keys) {
    final v = errors[k];
    if (v != null && v.isNotEmpty) return v;
  }
  return null;
}
