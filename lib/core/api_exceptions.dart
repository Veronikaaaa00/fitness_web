class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message =
        'Сервер просыпается или недоступен. Подождите 30–60 сек и нажмите «Войти» ещё раз.',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход'])
      : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Недостаточно прав'])
      : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Не найдено'])
      : super(statusCode: 404);
}

class ValidationException extends ApiException {
  const ValidationException(this.fields, [String message = 'Ошибка валидации'])
      : super(message, statusCode: 422);

  final Map<String, String> fields;
}

class ConflictException extends ApiException {
  const ConflictException([super.message = 'Конфликт данных'])
      : super(statusCode: 409);
}

/// Переводит сообщения PocketBase / Dio на русский.
String localizeApiMessage(String? raw, {int? status}) {
  if (raw == null || raw.trim().isEmpty) {
    return _fallbackForStatus(status);
  }
  final m = raw.trim();
  // Уже по-русски — оставляем.
  if (RegExp(r'[А-Яа-яЁё]').hasMatch(m)) return m;

  final lower = m.toLowerCase();

  const pairs = <List<String>>[
    ['failed to authenticate', 'Неверный email или пароль'],
    ['invalid login credentials', 'Неверный email или пароль'],
    ["the requested resource wasn't found", 'Запрошенный ресурс не найден'],
    ['the requested resource was not found', 'Запрошенный ресурс не найден'],
    ['something went wrong while processing your request', 'Ошибка при обработке запроса'],
    ['something went wrong', 'Ошибка при обработке запроса'],
    ['you are not allowed to perform this request', 'Недостаточно прав для этого действия'],
    ['missing or invalid collection context', 'Некорректный запрос к коллекции'],
    ['failed to create record', 'Не удалось создать запись'],
    ['failed to update record', 'Не удалось обновить запись'],
    ['failed to delete record', 'Не удалось удалить запись'],
    ['an error occurred while validating the submitted data', 'Ошибка проверки данных'],
    ['failed to validate', 'Ошибка проверки данных'],
    ['cannot be blank', 'Обязательное поле'],
    ['must be a valid email address', 'Некорректный email'],
    ['value must be a valid email address', 'Некорректный email'],
    ['the email is invalid or already in use', 'Email некорректен или уже занят'],
    ['values must be unique', 'Значение должно быть уникальным'],
    ['must be unique', 'Значение должно быть уникальным'],
    ['invalid or missing auth token', 'Сессия истекла — войдите снова'],
    ['the request requires valid record authorization token', 'Сессия истекла — войдите снова'],
    ['unauthorized', 'Требуется вход'],
    ['forbidden', 'Недостаточно прав'],
    ['not found', 'Не найдено'],
    ['conflict', 'Конфликт данных'],
    ['too many requests', 'Слишком много запросов, подождите'],
    ['connection errored', 'Нет соединения с сервером'],
    ['connection timeout', 'Превышено время ожидания сервера'],
    ['receive timeout', 'Превышено время ожидания ответа'],
    ['send timeout', 'Превышено время ожидания отправки'],
    ['the connection errored', 'Нет соединения с сервером'],
    ['xmlhttprequest error', 'Нет соединения с сервером'],
  ];

  for (final p in pairs) {
    if (lower.contains(p[0])) return p[1];
  }

  if (lower.contains('expected type') || lower.contains('must be of type')) {
    return 'Неверный тип значения';
  }
  if (lower.contains('maximum allowed value') ||
      lower.contains('must be no more than')) {
    return 'Значение слишком большое';
  }
  if (lower.contains('minimum allowed value') ||
      lower.contains('must be no less than')) {
    return 'Значение слишком маленькое';
  }
  if (lower.contains('must be in') && lower.contains('format')) {
    return 'Неверный формат значения';
  }

  // Любой неизвестный английский текст не показываем как есть.
  return _fallbackForStatus(status);
}

String _fallbackForStatus(int? status) {
  return switch (status) {
    400 => 'Ошибка запроса',
    401 => 'Требуется вход',
    403 => 'Недостаточно прав',
    404 => 'Запрошенный ресурс не найден',
    409 => 'Конфликт данных',
    422 => 'Ошибка проверки данных',
    429 => 'Слишком много запросов, подождите',
    500 || 502 || 503 => 'Ошибка сервера, попробуйте позже',
    _ => status == null ? 'Произошла ошибка' : 'Ошибка сервера ($status)',
  };
}

ApiException mapHttpError(int status, dynamic data) {
  String? message;
  Map<String, String> fields = {};
  if (data is Map) {
    message = data['message']?.toString();
    final raw = data['data'];
    if (raw is Map) {
      raw.forEach((k, v) {
        String fieldMsg;
        if (v is Map && v['message'] != null) {
          fieldMsg = '${v['message']}';
        } else if (v != null) {
          fieldMsg = '$v';
        } else {
          fieldMsg = '';
        }
        if (fieldMsg.isNotEmpty) {
          fields['$k'] = localizeApiMessage(fieldMsg, status: status);
        }
      });
    }
  }

  final localized = localizeApiMessage(message, status: status);

  return switch (status) {
    401 => UnauthorizedException(localized),
    403 => ForbiddenException(localized),
    404 => NotFoundException(localized),
    409 => ConflictException(localized),
    400 || 422 => fields.isEmpty
        ? ApiException(localized, statusCode: status)
        : ValidationException(fields, localized),
    _ => ApiException(localized, statusCode: status),
  };
}
