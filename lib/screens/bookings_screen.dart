import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/list_query.dart';
import '../models/booking.dart';
import '../models/fitness_class.dart';
import '../models/role.dart';
import '../repositories/bookings_repository.dart';
import '../state/auth_notifier.dart';
import '../state/load_status.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/network_banner.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/status_view.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  var _status = LoadStatus.loading;
  String? _error;
  var _page = 1;
  var _totalPages = 1;
  var _depsReady = false;
  List<Booking> _items = [];
  String? _busyId;

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

  bool get _isTrainerView {
    final role = context.read<AuthNotifier>().role;
    return role == Role.trainer;
  }

  void _syncUrl() {
    ListQuery(page: _page).go(context, '/bookings');
  }

  Future<void> _load({int? page}) async {
    final auth = context.read<AuthNotifier>();
    final userId = auth.user?.id;
    if (userId == null) return;

    setState(() {
      _status = LoadStatus.loading;
      _error = null;
      if (page != null) _page = page;
    });
    _syncUrl();
    try {
      final repo = context.read<BookingsRepository>();
      final result = _isTrainerView
          ? await repo.listForTrainerUser(userId: userId, page: _page)
          : await repo.listMine(memberId: userId, page: _page);
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
        _error = localizeApiMessage(e.message, status: e.statusCode);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = LoadStatus.error;
        _error = 'Не удалось загрузить записи';
      });
    }
  }

  Future<void> _showClassRoster(FitnessClass cls) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final result = await context.read<BookingsRepository>().listForClass(
            classId: cls.id,
            perPage: 100,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
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
                  Text(cls.title, style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${_fmt(cls.startsAt)} · записано ${attendees.length}/${cls.capacity}',
                  ),
                  const SizedBox(height: 16),
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
        const SnackBar(content: Text('Не удалось загрузить список')),
      );
    }
  }

  Future<void> _cancel(Booking booking) async {
    setState(() => _busyId = booking.id);
    try {
      await context.read<BookingsRepository>().cancel(
            bookingId: booking.id,
            classId: booking.classId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись отменена')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeApiMessage(e.message, status: e.statusCode)),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthNotifier>().role;
    final trainerView = role == Role.trainer;
    final title = trainerView ? 'Записи на мои занятия' : 'Мои записи';

    return AppScaffold(
      title: title,
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: _status != LoadStatus.success
                ? StatusView(
                    status: _status,
                    message: _error,
                    onRetry: _load,
                    emptyTitle: trainerView
                        ? 'Пока никто не записался'
                        : 'Записей пока нет',
                    emptySubtitle: trainerView
                        ? 'Клиенты появятся здесь после записи'
                        : 'Выберите занятие в расписании',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final cls = item.fitnessClass;
                      final busy = _busyId == item.id;
                      final subtitle = [
                        if (cls != null) _fmt(cls.startsAt),
                        if (trainerView && item.memberName.isNotEmpty)
                          item.memberName,
                        item.status.label,
                        if (cls?.roomName.isNotEmpty == true) cls!.roomName,
                      ].join(' · ');

                      return ListTile(
                        title: Text(cls?.title.isNotEmpty == true
                            ? cls!.title
                            : 'Занятие'),
                        subtitle: Text(
                          trainerView
                              ? [
                                  if (item.memberName.isNotEmpty)
                                    item.memberName
                                  else
                                    'Клиент',
                                  if (cls != null) _fmt(cls.startsAt),
                                  item.status.label,
                                ].join(' · ')
                              : subtitle,
                        ),
                        isThreeLine: true,
                        trailing: !trainerView &&
                                item.status == BookingStatus.confirmed
                            ? TextButton(
                                onPressed: busy ? null : () => _cancel(item),
                                child: busy
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Отменить'),
                              )
                            : trainerView
                                ? const Icon(Icons.person_outline)
                                : null,
                        onTap: trainerView && cls != null
                            ? () => _showClassRoster(cls)
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
