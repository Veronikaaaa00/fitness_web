import 'package:fitness_web/validation/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smoke: validators available', () {
    expect(Validators.email('user@example.com'), isNull);
  });
}
