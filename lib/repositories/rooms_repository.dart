import 'package:dio/dio.dart';

import '../models/page_result.dart';
import '../models/room.dart';
import 'pb_collection.dart';

class RoomsRepository {
  RoomsRepository(Dio dio) : _col = PbCollection(dio, 'rooms');

  final PbCollection _col;

  Future<PageResult<Room>> list({
    int page = 1,
    int perPage = 20,
    String? query,
    bool includeDeleted = false,
    String sort = 'name',
  }) {
    final parts = <String>[];
    if (includeDeleted) {
      parts.add('deleted=true');
    } else {
      parts.add('deleted=false');
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().replaceAll('"', '');
      parts.add('name~"$q"');
    }
    return _col.list(
      map: Room.fromJson,
      page: page,
      perPage: perPage,
      filter: parts.isEmpty ? null : parts.join(' && '),
      sort: sort,
    );
  }

  Future<Room> create(Room room) =>
      _col.create(room.toJson(), map: Room.fromJson);

  Future<Room> update(Room room) =>
      _col.update(room.id, room.toJson(), map: Room.fromJson);

  Future<Room> softDelete(String id) =>
      _col.update(id, {'deleted': true}, map: Room.fromJson);

  Future<Room> restore(String id) =>
      _col.update(id, {'deleted': false}, map: Room.fromJson);

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
