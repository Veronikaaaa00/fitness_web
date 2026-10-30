import 'package:fitness_web/core/api_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapHttpError 409', () {
    final e = mapHttpError(409, {'message': 'занято'});
    expect(e, isA<ConflictException>());
    expect(e.message, 'занято');
  });

  test('mapHttpError 422 with fields', () {
    final e = mapHttpError(422, {
      'message': 'invalid',
      'data': {
        'email': {'message': 'уже занят'},
      },
    });
    expect(e, isA<ValidationException>());
    expect((e as ValidationException).fields['email'], 'уже занят');
  });

  test('mapHttpError 401', () {
    expect(mapHttpError(401, null), isA<UnauthorizedException>());
  });
}
