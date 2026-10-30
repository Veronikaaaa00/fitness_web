import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/breakpoints.dart';
import '../core/permissions.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.contentMaxWidth = 960,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final double contentMaxWidth;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final auth = context.watch<AuthNotifier>();
    final destinations = _destinations(auth.role);
    final narrow = Breakpoints.isNarrow(context);
    final selected = _selectedIndex(location, destinations);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (auth.user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    '${auth.user!.fullName} (${auth.user!.role.label})',
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Выйти',
            onPressed: () async {
              await context.read<AuthNotifier>().logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
          ...?actions,
        ],
      ),
      drawer: narrow
          ? null
          : NavigationDrawer(
              selectedIndex: selected,
              onDestinationSelected: (i) {
                Navigator.of(context).pop();
                context.go(destinations[i].path);
              },
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: AppTheme.slate900),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'Фитнес-клуб',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                ),
                for (final d in destinations)
                  NavigationDrawerDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
      bottomNavigationBar: narrow
          ? NavigationBar(
              selectedIndex: selected.clamp(0, destinations.length - 1),
              onDestinationSelected: (i) => context.go(destinations[i].path),
              destinations: [
                for (final d in destinations.take(5))
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                    tooltip: d.label,
                  ),
              ],
            )
          : null,
      floatingActionButton: floatingActionButton,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = contentMaxWidth < constraints.maxWidth
              ? contentMaxWidth
              : constraints.maxWidth;
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: body,
            ),
          );
        },
      ),
    );
  }

  List<_NavItem> _destinations(Role? role) {
    final items = <_NavItem>[
      const _NavItem('/', 'Главная', Icons.home_outlined, Icons.home),
      const _NavItem(
        '/schedule',
        'Расписание',
        Icons.calendar_month_outlined,
        Icons.calendar_month,
      ),
    ];
    if (role == Role.member || role == Role.admin) {
      items.add(
        const _NavItem(
          '/profile',
          'Профиль',
          Icons.person_outline,
          Icons.person,
        ),
      );
    }
    if (Permissions.canViewOwnBookings(role)) {
      final bookingsLabel =
          role == Role.trainer ? 'Записи клиентов' : 'Мои записи';
      items.add(
        _NavItem(
          '/bookings',
          bookingsLabel,
          Icons.event_available_outlined,
          Icons.event_available,
        ),
      );
    }
    if (Permissions.canManageOwnClasses(role)) {
      items.add(
        const _NavItem(
          '/trainer/classes',
          'Мои занятия',
          Icons.fitness_center_outlined,
          Icons.fitness_center,
        ),
      );
    }
    if (Permissions.canManageCatalog(role)) {
      items.addAll([
        const _NavItem(
          '/admin/classes',
          'Занятия',
          Icons.event_note_outlined,
          Icons.event_note,
        ),
        const _NavItem(
          '/admin/rooms',
          'Залы',
          Icons.meeting_room_outlined,
          Icons.meeting_room,
        ),
        const _NavItem(
          '/admin/plans',
          'Тарифы',
          Icons.card_membership_outlined,
          Icons.card_membership,
        ),
        const _NavItem(
          '/admin/memberships',
          'Выдачи',
          Icons.assignment_ind_outlined,
          Icons.assignment_ind,
        ),
        const _NavItem(
          '/admin/equipment',
          'Инвентарь',
          Icons.fitness_center_outlined,
          Icons.fitness_center,
        ),
        const _NavItem(
          '/admin/trainers',
          'Тренеры',
          Icons.sports_outlined,
          Icons.sports,
        ),
        const _NavItem(
          '/admin/activity-types',
          'Типы',
          Icons.category_outlined,
          Icons.category,
        ),
        const _NavItem(
          '/admin/occupancy',
          'Загрузка',
          Icons.bar_chart_outlined,
          Icons.bar_chart,
        ),
      ]);
    }
    return items;
  }

  int _selectedIndex(String location, List<_NavItem> destinations) {
    for (var i = 0; i < destinations.length; i++) {
      final path = destinations[i].path;
      if (path == '/') {
        if (location == '/') return i;
      } else if (location.startsWith(path)) {
        return i;
      }
    }
    return 0;
  }
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
