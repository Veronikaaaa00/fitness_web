import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/fitness_class.dart';
import '../repositories/bookings_repository.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/classes_repository.dart';
import '../state/auth_notifier.dart';
import '../state/load_status.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/network_banner.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/status_view.dart';

class TrainerClassesScreen extends StatefulWidget {
  const TrainerClassesScreen({super.key});

  @override
  State<TrainerClassesScreen> createState() => _TrainerClassesScreenState();
}

class _TrainerClassesScreenState extends State<TrainerClassesScreen> {
  var _status = LoadStatus.loading;
  String? _error;
  var _page = 1;
  var _totalPages = 1;
  List<FitnessClass> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({int? page}) async {
    final userId = context.read<AuthNotifier>().user?.id;
    final catalog = context.read<CatalogRepository>();
    final classesRepo = context.read<ClassesRepository>();
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
      if (page != null) _page = page;
    });
    try {
      String? trainerId;
      if (userId != null) {
        final trainer = await catalog.trainerByUserId(userId);
        trainerId = trainer?.id;
      }
      final result = await classesRepo.list(
        page: _page,
        trainerId: trainerId,
        upcomingOnly: false,
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
        _error = 'Не удалось загрузить занятия';
      });
    }
  }

  Future<void> _openAttendees(FitnessClass item) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final result = await context.read<BookingsRepository>().listForClass(
            classId: item.id,
            perPage: 100,
          );
      if (!mounted) return;
      Navigator.of(context).pop(); // loader
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) {
          final attendees = result.items;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_fmt(item.startsAt)} · '
                    '${item.roomName.isEmpty ? 'зал не указан' : item.roomName} · '
                    'записано ${attendees.length}/${item.capacity}',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Кто записался',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (attendees.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Пока никто не записался'),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(ctx).height * 0.5,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: attendees.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final b = attendees[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text(
                                _initials(b.memberName),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            title: Text(
                              b.memberName.isEmpty
                                  ? 'Клиент ${b.memberId}'
                                  : b.memberName,
                            ),
                            subtitle: Text(b.status.label),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить записи')),
      );
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Мои занятия',
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: _status != LoadStatus.success
                ? StatusView(
                    status: _status,
                    message: _error,
                    onRetry: _load,
                    emptyTitle: 'У вас пока нет занятий в расписании',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        title: Text(item.title),
                        subtitle: Text(
                          '${_fmt(item.startsAt)} · '
                          '${item.roomName.isEmpty ? 'зал не указан' : item.roomName} · '
                          '${item.bookedCount}/${item.capacity}',
                        ),
                        isThreeLine: true,
                        trailing: FilledButton.tonal(
                          onPressed: () => _openAttendees(item),
                          child: const Text('Кто записан'),
                        ),
                        onTap: () => _openAttendees(item),
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
