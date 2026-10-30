import 'package:dio/dio.dart';

import '../models/membership_plan.dart';
import '../models/page_result.dart';
import 'pb_collection.dart';

class PlansRepository {
  PlansRepository(Dio dio) : _col = PbCollection(dio, 'membership_plans');

  final PbCollection _col;

  Future<PageResult<MembershipPlan>> list({
    int page = 1,
    int perPage = 20,
    String? query,
    bool includeDeleted = false,
    String sort = 'title',
  }) {
    final parts = <String>[];
    if (includeDeleted) {
      parts.add('deleted=true');
    } else {
      parts.add('deleted=false');
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().replaceAll('"', '');
      parts.add('title~"$q"');
    }
    return _col.list(
      map: MembershipPlan.fromJson,
      page: page,
      perPage: perPage,
      filter: parts.isEmpty ? null : parts.join(' && '),
      sort: sort,
    );
  }

  Future<MembershipPlan> create(MembershipPlan plan) =>
      _col.create(plan.toJson(), map: MembershipPlan.fromJson);

  Future<MembershipPlan> update(MembershipPlan plan) =>
      _col.update(plan.id, plan.toJson(), map: MembershipPlan.fromJson);

  Future<MembershipPlan> softDelete(String id) =>
      _col.update(id, {'deleted': true}, map: MembershipPlan.fromJson);

  Future<MembershipPlan> restore(String id) =>
      _col.update(id, {'deleted': false}, map: MembershipPlan.fromJson);

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
