import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/permissions.dart';
import 'models/role.dart';
import 'screens/admin_activity_types_screen.dart';
import 'screens/admin_classes_screen.dart';
import 'screens/admin_equipment_screen.dart';
import 'screens/admin_memberships_screen.dart';
import 'screens/admin_plans_screen.dart';
import 'screens/admin_rooms_screen.dart';
import 'screens/admin_trainers_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/occupancy_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/trainer_classes_screen.dart';
import 'state/auth_notifier.dart';

GoRouter createRouter(AuthNotifier auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      if (!auth.ready) return null;
      final loc = state.matchedLocation;
      final loggingIn = loc == '/login' || loc == '/register';

      if (!auth.isAuthenticated) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn) return '/';
      if (loc == '/forbidden') return null;

      final role = auth.role;
      if (loc.startsWith('/admin') && !Permissions.canManageCatalog(role)) {
        return '/forbidden';
      }
      if (loc.startsWith('/trainer') && !Permissions.canManageOwnClasses(role)) {
        return '/forbidden';
      }
      if (loc == '/bookings' && !Permissions.canViewOwnBookings(role)) {
        return '/forbidden';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const ScheduleScreen(),
      ),
      GoRoute(
        path: '/bookings',
        builder: (context, state) => const BookingsScreen(),
      ),
      GoRoute(
        path: '/trainer/classes',
        builder: (context, state) => const TrainerClassesScreen(),
      ),
      GoRoute(
        path: '/admin/rooms',
        builder: (context, state) => const AdminRoomsScreen(),
      ),
      GoRoute(
        path: '/admin/plans',
        builder: (context, state) => const AdminPlansScreen(),
      ),
      GoRoute(
        path: '/admin/occupancy',
        builder: (context, state) => const OccupancyScreen(),
      ),
      GoRoute(
        path: '/admin/classes',
        builder: (context, state) => const AdminClassesScreen(),
      ),
      GoRoute(
        path: '/admin/equipment',
        builder: (context, state) => const AdminEquipmentScreen(),
      ),
      GoRoute(
        path: '/admin/memberships',
        builder: (context, state) => const AdminMembershipsScreen(),
      ),
      GoRoute(
        path: '/admin/trainers',
        builder: (context, state) => const AdminTrainersScreen(),
      ),
      GoRoute(
        path: '/admin/activity-types',
        builder: (context, state) => const AdminActivityTypesScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Страница не найдена: ${state.uri}'),
      ),
    ),
  );
}

/// Удобный доступ к роли из виджетов без импорта модели везде.
Role? currentRole(BuildContext context) =>
    context.read<AuthNotifier>().role;
