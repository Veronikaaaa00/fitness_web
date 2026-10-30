import '../models/role.dart';

abstract final class Permissions {
  static bool canViewSchedule(Role? role) => role != null;

  static bool canBookClasses(Role? role) =>
      role == Role.member || role == Role.admin;

  static bool canViewOwnBookings(Role? role) =>
      role == Role.member || role == Role.admin || role == Role.trainer;

  static bool canManageOwnClasses(Role? role) =>
      role == Role.trainer || role == Role.admin;

  static bool canManageCatalog(Role? role) => role == Role.admin;

  static bool canManageUsers(Role? role) => role == Role.admin;

  static bool canViewOccupancyReport(Role? role) => role == Role.admin;

  static bool canHardDelete(Role? role) => role == Role.admin;

  static bool canRestore(Role? role) => role == Role.admin;
}
