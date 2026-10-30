import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/list_query.dart';
import '../models/equipment.dart';
import '../repositories/equipment_repository.dart';
import '../state/load_status.dart';
import '../validation/validators.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/network_banner.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/status_view.dart';

class AdminEquipmentScreen extends StatefulWidget {
  const AdminEquipmentScreen({super.key});

  @override
  State<AdminEquipmentScreen> createState() => _AdminEquipmentScreenState();
}

class _AdminEquipmentScreenState extends State<AdminEquipmentScreen> {
  final _query = TextEditingController();
  var _status = LoadStatus.loading;
  String? _error;
  var _page = 1;
  var _totalPages = 1;
  var _showDeleted = false;
  var _depsReady = false;
  List<Equipment> _items = [];
  final _selected = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_depsReady) return;
    _depsReady = true;
    final q = ListQuery.fromContext(context);
    _page = q.page;
    _query.text = q.q;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _syncUrl() {
    ListQuery(page: _page, q: _query.text).go(context, '/admin/equipment');
  }

  Future<void> _load({int? page}) async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
      if (page != null) _page = page;
    });
    _syncUrl();
    try {
      final result = await context.read<EquipmentRepository>().list(
            page: _page,
            includeDeleted: _showDeleted,
            query: _query.text,
          );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _selected.clear();
        _totalPages = result.totalPages.clamp(1, 9999);
        _status =
            result.items.isEmpty ? LoadStatus.empty : LoadStatus.success;
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
        _error = 'Не удалось загрузить инвентарь';
      });
    }
  }

  Future<void> _showEditor({Equipment? item}) async {
    final name = TextEditingController(text: item?.name ?? '');
    final qty =
        TextEditingController(text: item == null ? '10' : '${item.quantity}');
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Новый инвентарь' : 'Редактировать'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (v) => Validators.required(v, label: 'Название'),
              ),
              TextFormField(
                controller: qty,
                decoration: const InputDecoration(labelText: 'Количество'),
                keyboardType: TextInputType.number,
                validator: (v) => Validators.positiveInt(v, label: 'Количество'),
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
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    final body = Equipment(
      id: item?.id ?? '',
      name: name.text.trim(),
      quantity: int.parse(qty.text.trim()),
    );
    name.dispose();
    qty.dispose();
    if (saved != true || !mounted) return;

    try {
      final repo = context.read<EquipmentRepository>();
      if (item == null) {
        await repo.create(body);
      } else {
        await repo.update(body);
      }
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _softDelete(Equipment item) async {
    try {
      await context.read<EquipmentRepository>().softDelete(item.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _bulkSoftDelete() async {
    if (_selected.isEmpty) return;
    final ids = _selected.toList();
    try {
      final n =
          await context.read<EquipmentRepository>().softDeleteMany(ids);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Удалено записей: $n')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _restore(Equipment item) async {
    try {
      await context.read<EquipmentRepository>().restore(item.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _hardDelete(Equipment item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: Text('«${item.name}» будет удалён без восстановления.'),
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
      await context.read<EquipmentRepository>().hardDelete(item.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Инвентарь',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _query,
              decoration: InputDecoration(
                hintText: 'Поиск',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _load(page: 1),
                ),
              ),
              onSubmitted: (_) => _load(page: 1),
            ),
          ),
          Expanded(
            child: _status != LoadStatus.success
                ? StatusView(
                    status: _status,
                    message: _error,
                    onRetry: _load,
                    emptyTitle: 'Инвентаря нет',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        leading: item.deleted
                            ? null
                            : Checkbox(
                                value: _selected.contains(item.id),
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selected.add(item.id);
                                    } else {
                                      _selected.remove(item.id);
                                    }
                                  });
                                },
                              ),
                        title: Text(
                          item.deleted ? '${item.name} (удалён)' : item.name,
                        ),
                        subtitle: Text('Количество: ${item.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!item.deleted) ...[
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showEditor(item: item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _softDelete(item),
                              ),
                            ] else ...[
                              IconButton(
                                tooltip: 'Восстановить',
                                icon: const Icon(Icons.restore),
                                onPressed: () => _restore(item),
                              ),
                              IconButton(
                                tooltip: 'Удалить навсегда',
                                icon: const Icon(Icons.delete_forever),
                                onPressed: () => _hardDelete(item),
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
