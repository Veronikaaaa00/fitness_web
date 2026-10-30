import 'package:fitness_web/models/role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Role.fromApi', () {
    expect(Role.fromApi('admin'), Role.admin);
    expect(Role.fromApi('TRAINER'), Role.trainer);
    expect(Role.fromApi(null), Role.member);
    expect(Role.fromApi(''), Role.member);
  });
}
