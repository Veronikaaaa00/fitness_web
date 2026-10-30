import 'package:fitness_web/validation/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('bad'), isNotNull);
      expect(Validators.email('a@b.c'), isNull);
    });

    test('positiveInt', () {
      expect(Validators.positiveInt('0'), isNotNull);
      expect(Validators.positiveInt('-1'), isNotNull);
      expect(Validators.positiveInt('12'), isNull);
    });

    test('minLength', () {
      expect(Validators.minLength('ab', 3, label: 'X'), contains('минимум'));
      expect(Validators.minLength('abcd', 3, label: 'X'), isNull);
    });
  });
}
