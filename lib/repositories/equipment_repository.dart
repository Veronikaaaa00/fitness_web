import 'package:dio/dio.dart';

import '../models/equipment.dart';
import '../models/page_result.dart';
import 'pb_collection.dart';

class EquipmentRepository {
  EquipmentRepository(Dio dio) : _col = PbCollection(dio, 'equipment');

  final PbCollection _col;

  Future<PageResult<Equipment>> list({
    int page = 1,
    int perPage = 50,
    bool includeDeleted = false,
    String sort = 'name',
    String? query,
  }) {
    final parts = <String>[
      includeDeleted ? 'deleted=true' : 'deleted=false',
    ];
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().replaceAll('"', '');
      parts.add('name~"$q"');
    }
    return _col.list(
      map: Equipment.fromJson,
      page: page,
      perPage: perPage,
      filter: parts.join(' && '),
      sort: sort,
    );
  }

  Future<int> softDeleteMany(List<String> ids) async {
    var n = 0;
    for (final id in ids) {
      await softDelete(id);
      n++;
    }
    return n;
  }

  Future<Equipment> create(Equipment item) =>
      _col.create(item.toJson(), map: Equipment.fromJson);

  Future<Equipment> update(Equipment item) =>
      _col.update(item.id, item.toJson(), map: Equipment.fromJson);

  Future<Equipment> softDelete(String id) =>
      _col.update(id, {'deleted': true}, map: Equipment.fromJson);

  Future<Equipment> restore(String id) =>
      _col.update(id, {'deleted': false}, map: Equipment.fromJson);

  Future<void> hardDelete(String id) => _col.delete(id);
}
