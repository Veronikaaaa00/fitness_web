import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/list_query.dart';
import '../models/room.dart';
import '../repositories/rooms_repository.dart';
import '../state/load_status.dart';
import '../utils/form_api_errors.dart';
import '../validation/validators.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/network_banner.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/status_view.dart';

class AdminRoomsScreen extends StatefulWidget {
  const AdminRoomsScreen({super.key});

  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen> {
  var _status = LoadStatus.loading;
  String? _error;
  var _page = 1;
  var _totalPages = 1;
  var _showDeleted = false;
  var _depsReady = false;
  List<Room> _items = [];
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
    ListQuery(page: _page).go(context, '/admin/rooms');
  }

  Future<void> _load({int? page}) async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
      if (page != null) _page = page;
    });
    _syncUrl();
    try {
      final result = await context.read<RoomsRepository>().list(
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
        _error = 'Не удалось загрузить залы';
      });
    }
  }

  Future<void> _showEditor({Room? room}) async {
    final name = TextEditingController(text: room?.name ?? '');
    final capacity = TextEditingController(
      text: room == null ? '' : '${room.capacity}',
    );
    final description = TextEditingController(text: room?.description ?? '');
    final formKey = GlobalKey<FormState>();
    var serverErrors = <String, String>{};
    final repo = context.read<RoomsRepository>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(room == null ? 'Новый зал' : 'Редактировать зал'),
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
                  controller: capacity,
                  decoration: InputDecoration(
                    labelText: 'Вместимость',
                    errorText: serverFieldError(serverErrors, ['capacity']),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      Validators.positiveInt(v, label: 'Вместимость'),
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
                final body = Room(
                  id: room?.id ?? '',
                  name: name.text.trim(),
                  capacity: int.parse(capacity.text.trim()),
                  description: description.text.trim(),
                );
                try {
                  if (room == null) {
                    await repo.create(body);
                  } else {
                    await repo.update(body);
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
    capacity.dispose();
    description.dispose();
    if (saved == true && mounted) await _load();
  }

  Future<void> _bulkSoftDelete() async {
    if (_selected.isEmpty) return;
    try {
      final n = await context
          .read<RoomsRepository>()
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

  Future<void> _softDelete(Room room) async {
    try {
      await context.read<RoomsRepository>().softDelete(room.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _restore(Room room) async {
    try {
      await context.read<RoomsRepository>().restore(room.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _hardDelete(Room room) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: Text('Зал «${room.name}» будет удалён.'),
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
      await context.read<RoomsRepository>().hardDelete(room.id);
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
      title: 'Залы',
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
            _showDeleted ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                    emptyTitle: 'Залов нет',
                    emptySubtitle: 'Добавьте первый зал',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final room = _items[index];
                      return ListTile(
                        leading: room.deleted
                            ? null
                            : Checkbox(
                                value: _selected.contains(room.id),
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selected.add(room.id);
                                    } else {
                                      _selected.remove(room.id);
                                    }
                                  });
                                },
                              ),
                        title: Text(
                          room.deleted ? '${room.name} (удалён)' : room.name,
                        ),
                        subtitle: Text(
                          'Вместимость: ${room.capacity}'
                          '${room.description.isEmpty ? '' : ' · ${room.description}'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!room.deleted) ...[
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showEditor(room: room),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _softDelete(room),
                              ),
                            ] else ...[
                              IconButton(
                                tooltip: 'Восстановить',
                                icon: const Icon(Icons.restore),
                                onPressed: () => _restore(room),
                              ),
                              IconButton(
                                tooltip: 'Удалить навсегда',
                                icon: const Icon(Icons.delete_forever),
                                onPressed: () => _hardDelete(room),
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
