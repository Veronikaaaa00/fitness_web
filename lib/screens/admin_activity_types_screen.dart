import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/activity_type.dart';
import '../repositories/catalog_repository.dart';
import '../state/load_status.dart';
import '../utils/form_api_errors.dart';
import '../validation/validators.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/network_banner.dart';
import '../widgets/status_view.dart';

class AdminActivityTypesScreen extends StatefulWidget {
  const AdminActivityTypesScreen({super.key});

  @override
  State<AdminActivityTypesScreen> createState() =>
      _AdminActivityTypesScreenState();
}

class _AdminActivityTypesScreenState extends State<AdminActivityTypesScreen> {
  var _status = LoadStatus.loading;
  String? _error;
  var _showDeleted = false;
  List<ActivityType> _items = [];
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final items = await context
          .read<CatalogRepository>()
          .activityTypes(includeDeleted: _showDeleted);
      if (!mounted) return;
      setState(() {
        _items = items;
        _selected.clear();
        _status = items.isEmpty ? LoadStatus.empty : LoadStatus.success;
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
        _error = 'Не удалось загрузить типы';
      });
    }
  }

  Future<void> _showEditor({ActivityType? item}) async {
    final catalog = context.read<CatalogRepository>();
    final name = TextEditingController(text: item?.name ?? '');
    final description = TextEditingController(text: item?.description ?? '');
    final formKey = GlobalKey<FormState>();
    var serverErrors = <String, String>{};

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(item == null ? 'Новый тип' : 'Редактировать'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: 'Название',
                    errorText: serverFieldError(serverErrors, ['name']),
                  ),
                  validator: (v) => Validators.required(v, label: 'Название'),
                ),
                TextFormField(
                  controller: description,
                  decoration: InputDecoration(
                    labelText: 'Описание',
                    errorText: serverFieldError(serverErrors, ['description']),
                  ),
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final body = {
                  'name': name.text.trim(),
                  'description': description.text.trim(),
                  'deleted': false,
                };
                try {
                  if (item == null) {
                    await catalog.createActivityType(body);
                  } else {
                    await catalog.updateActivityType(item.id, body);
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (!ctx.mounted) return;
                  await handleFormApiError(
                    ctx,
                    error: e,
                    onValidation: (fields) =>
                        setLocal(() => serverErrors = fields),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    description.dispose();
    if (saved == true && mounted) await _load();
  }

  Future<void> _bulkSoftDelete() async {
    if (_selected.isEmpty) return;
    try {
      final n = await context
          .read<CatalogRepository>()
          .softDeleteActivityTypesMany(_selected.toList());
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Типы занятий',
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
            _load();
          },
          icon: Icon(
            _showDeleted
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ],
      floatingActionButton: _showDeleted
          ? null
          : FloatingActionButton(
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
                    emptyTitle: 'Типов нет',
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
                        subtitle: Text(
                          item.description.isEmpty
                              ? 'Без описания'
                              : item.description,
                        ),
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
                                onPressed: () async {
                                  await context
                                      .read<CatalogRepository>()
                                      .softDeleteActivityType(item.id);
                                  await _load();
                                },
                              ),
                            ] else ...[
                              IconButton(
                                icon: const Icon(Icons.restore),
                                onPressed: () async {
                                  await context
                                      .read<CatalogRepository>()
                                      .restoreActivityType(item.id);
                                  await _load();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever),
                                onPressed: () async {
                                  await context
                                      .read<CatalogRepository>()
                                      .hardDeleteActivityType(item.id);
                                  await _load();
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
