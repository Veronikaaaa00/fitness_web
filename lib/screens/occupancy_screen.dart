import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../repositories/classes_repository.dart';
import '../state/load_status.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/network_banner.dart';
import '../widgets/status_view.dart';

/// Отчёт «Загрузка залов» — заполненность занятий.
class OccupancyScreen extends StatefulWidget {
  const OccupancyScreen({super.key});

  @override
  State<OccupancyScreen> createState() => _OccupancyScreenState();
}

class _OccupancyScreenState extends State<OccupancyScreen> {
  var _status = LoadStatus.loading;
  String? _error;
  List<_RoomOccupancy> _rows = [];

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
      final result = await context.read<ClassesRepository>().list(
            page: 1,
            perPage: 100,
            upcomingOnly: false,
          );
      if (!mounted) return;
      final byRoom = <String, _RoomOccupancy>{};
      for (final c in result.items) {
        final key = c.roomId.isEmpty ? '—' : c.roomId;
        final name = c.roomName.isEmpty ? 'Без зала' : c.roomName;
        final row = byRoom.putIfAbsent(
          key,
          () => _RoomOccupancy(name: name),
        );
        row.classCount += 1;
        row.capacitySum += c.capacity;
        row.bookedSum += c.bookedCount;
      }
      final rows = byRoom.values.toList()
        ..sort((a, b) => b.occupancy.compareTo(a.occupancy));
      setState(() {
        _rows = rows;
        _status = rows.isEmpty ? LoadStatus.empty : LoadStatus.success;
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
        _error = 'Не удалось построить отчёт';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Загрузка залов',
      actions: [
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Обновить',
        ),
      ],
      body: Column(
        children: [
          const NetworkBanner(),
          Expanded(
            child: _status != LoadStatus.success
                ? StatusView(
                    status: _status,
                    message: _error,
                    onRetry: _load,
                    emptyTitle: 'Нет данных по занятиям',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rows.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  row.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Text('${(row.occupancy * 100).round()}%'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: row.occupancy),
                          const SizedBox(height: 4),
                          Text(
                            'занятий: ${row.classCount} · '
                            'записей: ${row.bookedSum}/${row.capacitySum}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RoomOccupancy {
  _RoomOccupancy({required this.name});

  final String name;
  int classCount = 0;
  int capacitySum = 0;
  int bookedSum = 0;

  double get occupancy =>
      capacitySum == 0 ? 0 : (bookedSum / capacitySum).clamp(0.0, 1.0);
}
