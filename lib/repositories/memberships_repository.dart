import 'package:dio/dio.dart';

import '../models/membership.dart';
import '../models/page_result.dart';
import 'pb_collection.dart';

class MembershipsRepository {
  MembershipsRepository(Dio dio) : _col = PbCollection(dio, 'memberships');

  final PbCollection _col;

  static const expand = 'member,plan';

  Future<PageResult<Membership>> list({
    int page = 1,
    int perPage = 20,
    String? memberId,
    String? query,
    String sort = '-endsAt',
  }) {
    final parts = <String>['deleted=false'];
    if (memberId != null && memberId.isNotEmpty) {
      parts.add('member="$memberId"');
    }
    return _col.list(
      map: Membership.fromJson,
      page: page,
      perPage: perPage,
      filter: parts.join(' && '),
      sort: sort,
      expand: expand,
    );
  }

  Future<Membership> issue({
    required String memberId,
    required String planId,
    required int durationDays,
  }) {
    final now = DateTime.now().toUtc();
    final ends = now.add(Duration(days: durationDays));
    return _col.create(
      {
        'member': memberId,
        'plan': planId,
        'startsAt': now.toIso8601String(),
        'endsAt': ends.toIso8601String(),
        'status': 'active',
        'deleted': false,
      },
      map: Membership.fromJson,
    );
  }

  Future<Membership> cancel(String id) =>
      _col.update(id, {'status': 'cancelled'}, map: Membership.fromJson);
}
