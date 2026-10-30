import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/list_query.dart';
import '../models/app_user.dart';
import '../models/membership.dart';
import '../models/membership_plan.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/memberships_repository.dart';
import '../repositories/plans_repository.dart';
import '../state/load_status.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/network_banner.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/status_view.dart';

class AdminMembershipsScreen extends StatefulWidget {
  const AdminMembershipsScreen({super.key});

  @override
  State<AdminMembershipsScreen> createState() => _AdminMembershipsScreenState();
}

class _AdminMembershipsScreenState extends State<AdminMembershipsScreen> {
  var _status = LoadStatus.loading;
  String? _error;
  var _page = 1;
  var _totalPages = 1;
  var _depsReady = false;
  List<Membership> _items = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_depsReady) return;
    _depsReady = true;
    _page = ListQuery.fromContext(context).page;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  void _syncUrl() {
    ListQuery(page: _page).go(context, '/admin/memberships');
  }

  Future<void> _load({int? page}) async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
      if (page != null) _page = page;
    });
    _syncUrl();
    try {
      final result =
          await context.read<MembershipsRepository>().list(page: _page);
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _totalPages = result.totalPages.clamp(1, 9999);
        _status = result.items.isEmpty ? LoadStatus.empty : LoadStatus.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = LoadStatus.error;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = LoadStatus.error;
        _error = 'Не удалось загрузить абонементы';
      });
    }
  }

  Future<void> _issue() async {
    final catalog = context.read<CatalogRepository>();
    final plansRepo = context.read<PlansRepository>();
    late final List<AppUser> members;
    late final List<MembershipPlan> plans;
    try {
      members = await catalog.members();
      plans = (await plansRepo.list(perPage: 100)).items;
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    if (members.isEmpty || plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нужны клиенты и тарифы')),
      );
      return;
    }

    var memberId = members.first.id;
    var plan = plans.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Выдать абонемент'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: memberId,
                decoration: const InputDecoration(labelText: 'Клиент'),
                items: [
                  for (final m in members)
                    DropdownMenuItem(
                      value: m.id,
                      child: Text('${m.fullName} (${m.email})'),
                    ),
                ],
                onChanged: (v) => setLocal(() => memberId = v ?? memberId),
              ),
              DropdownButtonFormField<String>(
                initialValue: plan.id,
                decoration: const InputDecoration(labelText: 'Тариф'),
                items: [
                  for (final p in plans)
                    DropdownMenuItem(value: p.id, child: Text(p.title)),
                ],
                onChanged: (v) {
                  final next = plans.firstWhere((p) => p.id == v);
                  setLocal(() => plan = next);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Выдать'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await context.read<MembershipsRepository>().issue(
            memberId: memberId,
            planId: plan.id,
            durationDays: plan.durationDays,
          );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _cancel(Membership m) async {
    try {
      await context.read<MembershipsRepository>().cancel(m.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Выданные абонементы',
      floatingActionButton: FloatingActionButton(
        onPressed: _issue,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: _status != LoadStatus.success
                ? StatusView(
                    status: _status,
                    message: _error,
                    onRetry: _load,
                    emptyTitle: 'Абонементов нет',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final m = _items[index];
                      return ListTile(
                        title: Text(
                          m.memberName.isEmpty ? m.memberId : m.memberName,
                        ),
                        subtitle: Text(
                          '${m.planTitle} · ${m.status} · до ${_fmt(m.endsAt)}',
                        ),
                        trailing: m.status == 'active'
                            ? TextButton(
                                onPressed: () => _cancel(m),
                                child: const Text('Отменить'),
                              )
                            : null,
                      );
                    },
                  ),
          ),
          PaginationBar(
            page: _page,
            totalPages: _totalPages,
            onPageChanged: (p) => _load(page: p),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}
