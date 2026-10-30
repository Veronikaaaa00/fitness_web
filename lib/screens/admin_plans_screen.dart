import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/list_query.dart';
import '../models/membership_plan.dart';
import '../repositories/plans_repository.dart';
import '../state/load_status.dart';
import '../validation/validators.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/network_banner.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/status_view.dart';

class AdminPlansScreen extends StatefulWidget {
  const AdminPlansScreen({super.key});

  @override
  State<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends State<AdminPlansScreen> {
  var _status = LoadStatus.loading;
  String? _error;
  var _page = 1;
  var _totalPages = 1;
  var _showDeleted = false;
  var _depsReady = false;
  List<MembershipPlan> _items = [];
  final _selected = <String>{};

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
    ListQuery(page: _page).go(context, '/admin/plans');
  }

  Future<void> _load({int? page}) async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
      if (page != null) _page = page;
    });
    _syncUrl();
    try {
      final result = await context.read<PlansRepository>().list(
            page: _page,
            includeDeleted: _showDeleted,
          );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _selected.clear();
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
        _error = 'Не удалось загрузить тарифы';
      });
    }
  }

  Future<void> _bulkSoftDelete() async {
    if (_selected.isEmpty) return;
    try {
      final n = await context
          .read<PlansRepository>()
          .softDeleteMany(_selected.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Удалено: $n')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showEditor({MembershipPlan? plan}) async {
    final title = TextEditingController(text: plan?.title ?? '');
    final days = TextEditingController(
      text: plan == null ? '30' : '${plan.durationDays}',
    );
    final price = TextEditingController(
      text: plan == null ? '' : '${plan.price}',
    );
    final description = TextEditingController(text: plan?.description ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(plan == null ? 'Новый тариф' : 'Редактировать тариф'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (v) => Validators.required(v, label: 'Название'),
              ),
              TextFormField(
                controller: days,
                decoration: const InputDecoration(labelText: 'Дней'),
                keyboardType: TextInputType.number,
                validator: (v) => Validators.positiveInt(v, label: 'Дней'),
              ),
              TextFormField(
                controller: price,
                decoration: const InputDecoration(labelText: 'Цена'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final base = Validators.required(v, label: 'Цена');
                  if (base != null) return base;
                  final n = double.tryParse(v!.trim().replaceAll(',', '.'));
                  if (n == null || n < 0) return 'Цена: число ≥ 0';
                  return null;
                },
              ),
              TextFormField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Описание'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) {
      title.dispose();
      days.dispose();
      price.dispose();
      description.dispose();
      return;
    }

    final body = MembershipPlan(
      id: plan?.id ?? '',
      title: title.text.trim(),
      durationDays: int.parse(days.text.trim()),
      price: double.parse(price.text.trim().replaceAll(',', '.')),
      description: description.text.trim(),
    );
    title.dispose();
    days.dispose();
    price.dispose();
    description.dispose();

    try {
      final repo = context.read<PlansRepository>();
      if (plan == null) {
        await repo.create(body);
      } else {
        await repo.update(body);
      }
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _softDelete(MembershipPlan plan) async {
    try {
      await context.read<PlansRepository>().softDelete(plan.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _restore(MembershipPlan plan) async {
    try {
      await context.read<PlansRepository>().restore(plan.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _hardDelete(MembershipPlan plan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: Text('Тариф «${plan.title}» будет удалён без восстановления.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<PlansRepository>().hardDelete(plan.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Тарифы',
      actions: [
        if (_selected.isNotEmpty && !_showDeleted)
          IconButton(
            tooltip: 'Удалить выбранные',
            onPressed: _bulkSoftDelete,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        IconButton(
          tooltip: _showDeleted ? 'Скрыть удалённые' : 'Показать удалённые',
          onPressed: () {
            setState(() => _showDeleted = !_showDeleted);
            _load(page: 1);
          },
          icon: Icon(
            _showDeleted
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(),
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
                    emptyTitle: 'Тарифов нет',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final plan = _items[index];
                      return ListTile(
                        leading: plan.deleted
                            ? null
                            : Checkbox(
                                value: _selected.contains(plan.id),
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selected.add(plan.id);
                                    } else {
                                      _selected.remove(plan.id);
                                    }
                                  });
                                },
                              ),
                        title: Text(
                          plan.deleted
                              ? '${plan.title} (удалён)'
                              : plan.title,
                        ),
                        subtitle: Text(
                          '${plan.durationDays} дн. · ${plan.price.toStringAsFixed(0)} ₽',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!plan.deleted) ...[
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showEditor(plan: plan),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _softDelete(plan),
                              ),
                            ] else ...[
                              IconButton(
                                tooltip: 'Восстановить',
                                icon: const Icon(Icons.restore),
                                onPressed: () => _restore(plan),
                              ),
                              IconButton(
                                tooltip: 'Удалить навсегда',
                                icon: const Icon(Icons.delete_forever),
                                onPressed: () => _hardDelete(plan),
                              ),
                            ],
                          ],
                        ),
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
}
