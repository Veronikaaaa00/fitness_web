import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/permissions.dart';
import '../models/fitness_class.dart';
import '../models/room.dart';
import '../models/trainer.dart';
import '../repositories/bookings_repository.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/classes_repository.dart';
import '../repositories/rooms_repository.dart';
import '../state/auth_notifier.dart';
import '../state/load_status.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/network_banner.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/status_view.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _query = TextEditingController();
  var _status = LoadStatus.loading;
  String? _error;
  var _page = 1;
  var _sort = 'startsAt';
  var _totalPages = 1;
  var _depsReady = false;
  String? _roomId;
  String? _trainerId;
  List<FitnessClass> _items = [];
  List<Room> _rooms = [];
  List<Trainer> _trainers = [];
  String? _bookingBusyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_depsReady) return;
    _depsReady = true;
    final q = GoRouterState.of(context).uri.queryParameters;
    _page = int.tryParse(q['page'] ?? '') ?? 1;
    _sort = q['sort'] ?? 'startsAt';
    _query.text = q['q'] ?? '';
    _roomId = q['room'];
    _trainerId = q['trainer'];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadFilters();
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    final roomsRepo = context.read<RoomsRepository>();
    final catalog = context.read<CatalogRepository>();
    try {
      final rooms = await roomsRepo.list(page: 1, perPage: 100);
      final trainers = await catalog.trainers();
      if (!mounted) return;
      setState(() {
        _rooms = rooms.items;
        _trainers = trainers;
      });
    } catch (_) {}
  }

  void _syncUrl() {
    final params = <String, String>{
      if (_page > 1) 'page': '$_page',
      if (_query.text.trim().isNotEmpty) 'q': _query.text.trim(),
      if (_sort != 'startsAt') 'sort': _sort,
      if (_roomId != null && _roomId!.isNotEmpty) 'room': _roomId!,
      if (_trainerId != null && _trainerId!.isNotEmpty) 'trainer': _trainerId!,
    };
    context.go(Uri(path: '/schedule', queryParameters: params).toString());
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
            query: _query.text,
            sort: _sort,
            roomId: _roomId,
            trainerId: _trainerId,
          );
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
        _error = 'Не удалось загрузить расписание';
      });
    }
  }

  Future<void> _book(FitnessClass item) async {
    final memberId = context.read<AuthNotifier>().user?.id;
    if (memberId == null) return;

    setState(() => _bookingBusyId = item.id);
    try {
      await context.read<BookingsRepository>().book(
            memberId: memberId,
            classId: item.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы записаны на занятие')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _bookingBusyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canBook =
        Permissions.canBookClasses(context.watch<AuthNotifier>().role);

    return AppScaffold(
      title: 'Расписание',
      body: Column(
        children: [
          const NetworkBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _query,
                    decoration: const InputDecoration(
                      hintText: 'Поиск по названию',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _load(page: 1),
                  ),
                ),
                DropdownButton<String?>(
                  value: _roomId,
                  hint: const Text('Зал'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Все залы'),
                    ),
                    for (final r in _rooms)
                      DropdownMenuItem(value: r.id, child: Text(r.name)),
                  ],
                  onChanged: (v) {
                    setState(() => _roomId = v);
                    _load(page: 1);
                  },
                ),
                DropdownButton<String?>(
                  value: _trainerId,
                  hint: const Text('Тренер'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Все тренеры'),
                    ),
                    for (final t in _trainers)
                      DropdownMenuItem(value: t.id, child: Text(t.fullName)),
                  ],
                  onChanged: (v) {
                    setState(() => _trainerId = v);
                    _load(page: 1);
                  },
                ),
                DropdownButton<String>(
                  value: _sort,
                  items: const [
                    DropdownMenuItem(
                      value: 'startsAt',
                      child: Text('Сначала ближайшие'),
                    ),
                    DropdownMenuItem(
                      value: '-startsAt',
                      child: Text('Сначала поздние'),
                    ),
                    DropdownMenuItem(
                      value: 'title',
                      child: Text('По названию'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _sort = v);
                    _load(page: 1);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _load(page: 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: _status != LoadStatus.success
                ? StatusView(
                    status: _status,
                    message: _error,
                    onRetry: _load,
                    emptyTitle: 'Нет ближайших занятий',
                    emptySubtitle: 'Попробуйте другой запрос или зайдите позже',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final busy = _bookingBusyId == item.id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        title: Text(item.title),
                        subtitle: Text(
                          [
                            _fmt(item.startsAt),
                            if (item.roomName.isNotEmpty) item.roomName,
                            if (item.trainerName.isNotEmpty) item.trainerName,
                            'мест: ${item.seatsLeft}/${item.capacity}',
                          ].join(' · '),
                        ),
                        isThreeLine: true,
                        trailing: canBook
                            ? FilledButton.tonal(
                                onPressed: item.isFull || busy
                                    ? null
                                    : () => _book(item),
                                child: busy
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        item.isFull ? 'Мест нет' : 'Записаться',
                                      ),
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

  String _fmt(DateTime dt) {
    final d =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }
}
