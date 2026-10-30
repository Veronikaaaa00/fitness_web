import 'package:fitness_web/core/permissions.dart';
import 'package:fitness_web/models/role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('member permissions', () {
    expect(Permissions.canBookClasses(Role.member), isTrue);
    expect(Permissions.canViewOwnBookings(Role.member), isTrue);
    expect(Permissions.canManageCatalog(Role.member), isFalse);
    expect(Permissions.canHardDelete(Role.member), isFalse);
  });

  test('trainer permissions', () {
    expect(Permissions.canManageOwnClasses(Role.trainer), isTrue);
    expect(Permissions.canViewOwnBookings(Role.trainer), isTrue);
    expect(Permissions.canBookClasses(Role.trainer), isFalse);
    expect(Permissions.canManageCatalog(Role.trainer), isFalse);
  });

  test('admin permissions', () {
    expect(Permissions.canManageCatalog(Role.admin), isTrue);
    expect(Permissions.canHardDelete(Role.admin), isTrue);
    expect(Permissions.canBookClasses(Role.admin), isTrue);
    expect(Permissions.canViewOccupancyReport(Role.admin), isTrue);
  });
}
