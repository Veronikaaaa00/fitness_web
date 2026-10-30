import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../models/trainer.dart';
import '../repositories/catalog_repository.dart';
import '../state/load_status.dart';
import '../utils/form_api_errors.dart';
import '../validation/validators.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/network_banner.dart';
import '../widgets/status_view.dart';

class AdminTrainersScreen extends StatefulWidget {
  const AdminTrainersScreen({super.key});

  @override
  State<AdminTrainersScreen> createState() => _AdminTrainersScreenState();
}

class _AdminTrainersScreenState extends State<AdminTrainersScreen> {
  var _status = LoadStatus.loading;
  String? _error;
  var _showDeleted = false;
  List<Trainer> _items = [];
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
          .trainers(includeDeleted: _showDeleted);
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
        _error = 'Не удалось загрузить тренеров';
      });
    }
  }

  Future<void> _showEditor({Trainer? item}) async {
    final catalog = context.read<CatalogRepository>();
    late final List<AppUser> users;
    try {
      users = (await catalog.usersPage(perPage: 100)).items;
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет пользователей для привязки')),
      );
      return;
    }

    final name = TextEditingController(text: item?.fullName ?? '');
    final bio = TextEditingController(text: item?.bio ?? '');
    var userId = item?.userId.isNotEmpty == true ? item!.userId : users.first.id;
    final formKey = GlobalKey<FormState>();
    var serverErrors = <String, String>{};

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(item == null ? 'Новый тренер' : 'Редактировать'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: users.any((u) => u.id == userId)
                        ? userId
                        : users.first.id,
                    decoration: InputDecoration(
                      labelText: 'Пользователь',
                      errorText: serverFieldError(serverErrors, ['user']),
                    ),
                    items: [
                      for (final u in users)
                        DropdownMenuItem(
                          value: u.id,
                          child: Text('${u.fullName} (${u.email})'),
                        ),
                    ],
                    onChanged: (v) => setLocal(() => userId = v ?? userId),
                  ),
                  TextFormField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: 'ФИО',
                      errorText:
                          serverFieldError(serverErrors, ['fullName', 'name']),
                    ),
                    validator: (v) => Validators.required(v, label: 'ФИО'),
                  ),
                  TextFormField(
                    controller: bio,
                    decoration: InputDecoration(
                      labelText: 'О себе',
                      errorText: serverFieldError(serverErrors, ['bio']),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
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
                  'user': userId,
                  'fullName': name.text.trim(),
                  'bio': bio.text.trim(),
                  'deleted': false,
                };
                try {
                  if (item == null) {
                    await catalog.createTrainer(body);
                  } else {
                    await catalog.updateTrainer(item.id, body);
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
    bio.dispose();
    if (saved == true && mounted) await _load();
  }

  Future<void> _bulkSoftDelete() async {
    if (_selected.isEmpty) return;
    try {
      final n = await context
          .read<CatalogRepository>()
          .softDeleteTrainersMany(_selected.toList());
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
      title: 'Тренеры',
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
                    emptyTitle: 'Тренеров нет',
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
                          item.deleted
                              ? '${item.fullName} (удалён)'
                              : item.fullName,
                        ),
                        subtitle: Text(
                          item.bio.isEmpty ? 'Без описания' : item.bio,
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
                                      .softDeleteTrainer(item.id);
                                  await _load();
                                },
                              ),
                            ] else ...[
                              IconButton(
                                icon: const Icon(Icons.restore),
                                onPressed: () async {
                                  await context
                                      .read<CatalogRepository>()
                                      .restoreTrainer(item.id);
                                  await _load();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever),
                                onPressed: () async {
                                  await context
                                      .read<CatalogRepository>()
                                      .hardDeleteTrainer(item.id);
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
