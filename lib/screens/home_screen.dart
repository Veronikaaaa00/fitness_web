import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/permissions.dart';
import '../state/auth_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/network_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    final role = auth.role;

    return AppScaffold(
      title: 'Главная',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const NetworkBanner(),
          Text(
            'Здравствуйте, ${user?.fullName ?? ''}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Роль: ${user?.role.label ?? '—'}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionTile(
                icon: Icons.calendar_month,
                label: 'Расписание',
                onTap: () => context.go('/schedule'),
              ),
              if (Permissions.canViewOwnBookings(role))
                _ActionTile(
                  icon: Icons.event_available,
                  label: role?.name == 'trainer'
                      ? 'Записи клиентов'
                      : 'Мои записи',
                  onTap: () => context.go('/bookings'),
                ),
              if (Permissions.canManageOwnClasses(role))
                _ActionTile(
                  icon: Icons.fitness_center,
                  label: 'Мои занятия',
                  onTap: () => context.go('/trainer/classes'),
                ),
              if (Permissions.canManageCatalog(role)) ...[
                _ActionTile(
                  icon: Icons.event_note,
                  label: 'Занятия',
                  onTap: () => context.go('/admin/classes'),
                ),
                _ActionTile(
                  icon: Icons.meeting_room,
                  label: 'Залы',
                  onTap: () => context.go('/admin/rooms'),
                ),
                _ActionTile(
                  icon: Icons.card_membership,
                  label: 'Тарифы',
                  onTap: () => context.go('/admin/plans'),
                ),
                _ActionTile(
                  icon: Icons.assignment_ind,
                  label: 'Выдачи',
                  onTap: () => context.go('/admin/memberships'),
                ),
                _ActionTile(
                  icon: Icons.inventory_2,
                  label: 'Инвентарь',
                  onTap: () => context.go('/admin/equipment'),
                ),
                _ActionTile(
                  icon: Icons.bar_chart,
                  label: 'Загрузка залов',
                  onTap: () => context.go('/admin/occupancy'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: AppTheme.slate800),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.slate800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
