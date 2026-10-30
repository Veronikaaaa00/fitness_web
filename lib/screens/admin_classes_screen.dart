import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/list_query.dart';
import '../models/activity_type.dart';
import '../models/fitness_class.dart';
import '../models/room.dart';
import '../models/trainer.dart';
import '../models/equipment.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/class_equipment_repository.dart';
import '../repositories/classes_repository.dart';
import '../repositories/equipment_repository.dart';
import '../repositories/rooms_repository.dart';
import '../state/load_status.dart';
import '../validation/validators.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/network_banner.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/status_view.dart';
import '../widgets/string_multi_select.dart';

class AdminClassesScreen extends StatefulWidget {
  const AdminClassesScreen({super.key});

  @override
  State<AdminClassesScreen> createState() => _AdminClassesScreenState();
}

class _AdminClassesScreenState extends State<AdminClassesScreen> {
  var _status = LoadStatus.loading;
  String? _error;
  var _page = 1;
  var _totalPages = 1;
  var _showDeleted = false;
  var _depsReady = false;
  List<FitnessClass> _items = [];
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
    ListQuery(page: _page).go(context, '/admin/classes');
  }

  Future<void> _load({int? page}) async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
      if (page != null) _page = page;
    });
    _syncUrl();
    try {
      final result = await context.read<ClassesRepository>().list(
            page: _page,
            upcomingOnly: false,
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
        _error = 'Не удалось загрузить занятия';
      });
    }
  }

  Future<void> _bulkSoftDelete() async {
    if (_selected.isEmpty) return;
    try {
      final n = await context
          .read<ClassesRepository>()
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

  Future<void> _showEditor({FitnessClass? item}) async {
    final catalog = context.read<CatalogRepository>();
    final roomsRepo = context.read<RoomsRepository>();
    final equipmentRepo = context.read<EquipmentRepository>();
    final classEquipRepo = context.read<ClassEquipmentRepository>();
    late final List<Room> rooms;
    late final List<Trainer> trainers;
    late final List<ActivityType> types;
    late final List<Equipment> equipment;
    var selectedEquipment = <String>[];
    try {
      rooms = (await roomsRepo.list(perPage: 100)).items;
      trainers = await catalog.trainers();
      types = await catalog.activityTypes();
      equipment = (await equipmentRepo.list(perPage: 100)).items;
      if (item != null) {
        final links = await classEquipRepo.forClass(item.id);
        selectedEquipment = links.map((e) => e.equipmentId).toList();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    if (!mounted) return;
    if (rooms.isEmpty || trainers.isEmpty || types.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала создайте залы, тренеров и типы занятий')),
      );
      return;
    }

    final title = TextEditingController(text: item?.title ?? '');
    final capacity = TextEditingController(
      text: item == null ? '12' : '${item.capacity}',
    );
    var roomId = item?.roomId.isNotEmpty == true ? item!.roomId : rooms.first.id;
    var trainerId =
        item?.trainerId.isNotEmpty == true ? item!.trainerId : trainers.first.id;
    var typeId = item?.activityTypeId.isNotEmpty == true
        ? item!.activityTypeId
        : types.first.id;
    var starts = item?.startsAt ?? DateTime.now().add(const Duration(days: 1, hours: 2));
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(item == null ? 'Новое занятие' : 'Редактировать'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Название'),
                      validator: (v) => Validators.required(v, label: 'Название'),
                    ),
                    TextFormField(
                      controller: capacity,
                      decoration: const InputDecoration(labelText: 'Вместимость'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          Validators.positiveInt(v, label: 'Вместимость'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: roomId,
                      decoration: const InputDecoration(labelText: 'Зал'),
                      items: [
                        for (final r in rooms)
                          DropdownMenuItem(value: r.id, child: Text(r.name)),
                      ],
                      onChanged: (v) => setLocal(() => roomId = v ?? roomId),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: trainerId,
                      decoration: const InputDecoration(labelText: 'Тренер'),
                      items: [
                        for (final t in trainers)
                          DropdownMenuItem(value: t.id, child: Text(t.fullName)),
                      ],
                      onChanged: (v) => setLocal(() => trainerId = v ?? trainerId),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: typeId,
                      decoration: const InputDecoration(labelText: 'Тип'),
                      items: [
                        for (final t in types)
                          DropdownMenuItem(value: t.id, child: Text(t.name)),
                      ],
                      onChanged: (v) => setLocal(() => typeId = v ?? typeId),
                    ),
                    const SizedBox(height: 8),
                    StringMultiSelectField(
                      label: 'Инвентарь (M:N)',
                      options: [
                        for (final e in equipment)
                          StringOption(id: e.id, label: e.name),
                      ],
                      value: selectedEquipment,
                      onChanged: (v) => setLocal(() => selectedEquipment = v),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Старт: ${_fmt(starts)}',
                      ),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: starts,
                        );
                        if (date == null || !ctx.mounted) return;
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.fromDateTime(starts),
                        );
                        if (time == null) return;
                        setLocal(() {
                          starts = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
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
      ),
    );

    final body = {
      'title': title.text.trim(),
      'capacity': int.parse(capacity.text.trim()),
      'room': roomId,
      'trainer': trainerId,
      'activityType': typeId,
      'startsAt': starts.toUtc().toIso8601String(),
      'endsAt': starts.add(const Duration(hours: 1)).toUtc().toIso8601String(),
      'cancelled': false,
      'deleted': false,
      if (item == null) 'bookedCount': 0,
    };
    title.dispose();
    capacity.dispose();

    if (saved != true || !mounted) return;

    final repo = context.read<ClassesRepository>();
    final linkRepo = context.read<ClassEquipmentRepository>();
    try {
      final savedClass = item == null
          ? await repo.create(body)
          : await repo.update(item.id, body);
      await linkRepo.sync(
        classId: savedClass.id,
        equipmentIds: selectedEquipment,
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _softDelete(FitnessClass item) async {
    try {
      await context.read<ClassesRepository>().softDelete(item.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _restore(FitnessClass item) async {
    try {
      await context.read<ClassesRepository>().restore(item.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _hardDelete(FitnessClass item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: Text('Занятие «${item.title}» будет удалено без восстановления.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ClassesRepository>().hardDelete(item.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Занятия',
      actions: [
        if (_selected.isNotEmpty && !_showDeleted)
          IconButton(
            tooltip: 'Удалить выбранные',
            onPressed: _bulkSoftDelete,
            icon: const Icon(Icons.delete_sweep_outlined),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Показать удалённые'),
              value: _showDeleted,
              onChanged: (v) {
                setState(() {
                  _showDeleted = v;
                  _page = 1;
                });
                _load(page: 1);
              },
            ),
          ),
          Expanded(
            child: _status != LoadStatus.success
                ? StatusView(
                    status: _status,
                    message: _error,
                    onRetry: _load,
                    emptyTitle: 'Занятий нет',
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
                          item.deleted ? '${item.title} (удалён)' : item.title,
                        ),
                        subtitle: Text(
                          '${_fmt(item.startsAt)} · ${item.roomName} · '
                          '${item.trainerName} · ${item.bookedCount}/${item.capacity}',
                        ),
                        isThreeLine: true,
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
                                icon: const Icon(Icons.restore),
                                onPressed: () => _restore(item),
                              ),
                              IconButton(
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

  String _fmt(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }
}
