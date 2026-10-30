typedef FieldValidator = String? Function(String? value);

class Validators {
  Validators._();

  static String? required(String? value, {String label = 'Поле'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label обязательно';
    }
    return null;
  }

  static String? email(String? value) {
    final base = required(value, label: 'Email');
    if (base != null) return base;
    final v = value!.trim();
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
    if (!ok) return 'Некорректный email';
    return null;
  }

  static String? minLength(String? value, int min, {String label = 'Поле'}) {
    if (value == null || value.trim().length < min) {
      return '$label: минимум $min символов';
    }
    return null;
  }

  static String? maxLength(String? value, int max, {String label = 'Поле'}) {
    if (value != null && value.trim().length > max) {
      return '$label: не больше $max символов';
    }
    return null;
  }

  static String? positiveInt(String? value, {String label = 'Значение'}) {
    final base = required(value, label: label);
    if (base != null) return base;
    final n = int.tryParse(value!.trim());
    if (n == null) return '$label: целое число';
    if (n <= 0) return '$label: должно быть больше 0';
    return null;
  }

  static String? phone(String? value) {
    final base = required(value, label: 'Телефон');
    if (base != null) return base;
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Телефон: 10–15 цифр';
    }
    return null;
  }

  static FieldValidator compose(List<FieldValidator> list) {
    return (value) {
      for (final v in list) {
        final error = v(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
