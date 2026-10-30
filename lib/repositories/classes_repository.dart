import 'package:dio/dio.dart';

import '../models/fitness_class.dart';
import '../models/page_result.dart';
import 'pb_collection.dart';

class ClassesRepository {
  ClassesRepository(Dio dio) : _col = PbCollection(dio, 'classes');

  final PbCollection _col;

  static const expand = 'room,trainer,activityType';

  Future<PageResult<FitnessClass>> list({
    int page = 1,
    int perPage = 20,
    String? roomId,
    String? trainerId,
    String? query,
    bool upcomingOnly = true,
    bool includeDeleted = false,
    String sort = 'startsAt',
  }) {
    final parts = <String>[];
    parts.add(includeDeleted ? 'deleted=true' : 'deleted=false');
    parts.add('cancelled=false');
    if (upcomingOnly) {
      final now = DateTime.now().toUtc().toIso8601String();
      parts.add('startsAt>="$now"');
    }
    if (roomId != null && roomId.isNotEmpty) {
      parts.add('room="$roomId"');
    }
    if (trainerId != null && trainerId.isNotEmpty) {
      parts.add('trainer="$trainerId"');
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().replaceAll('"', '');
      parts.add('title~"$q"');
    }
    return _col.list(
      map: FitnessClass.fromJson,
      page: page,
      perPage: perPage,
      filter: parts.join(' && '),
      sort: sort,
      expand: expand,
    );
  }

  Future<FitnessClass> getById(String id) =>
      _col.getOne(id, map: FitnessClass.fromJson, expand: expand);

  Future<FitnessClass> create(Map<String, dynamic> body) =>
      _col.create(body, map: FitnessClass.fromJson);

  Future<FitnessClass> update(String id, Map<String, dynamic> body) =>
      _col.update(id, body, map: FitnessClass.fromJson);

  Future<FitnessClass> softDelete(String id) =>
      _col.update(id, {'deleted': true}, map: FitnessClass.fromJson);

  Future<FitnessClass> restore(String id) =>
      _col.update(id, {'deleted': false}, map: FitnessClass.fromJson);

  Future<void> hardDelete(String id) => _col.delete(id);

  Future<int> softDeleteMany(List<String> ids) async {
    var n = 0;
    for (final id in ids) {
      await softDelete(id);
      n++;
    }
    return n;
  }
}
