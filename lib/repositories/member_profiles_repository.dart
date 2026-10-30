import 'package:dio/dio.dart';

import '../models/member_profile.dart';
import 'pb_collection.dart';

class MemberProfilesRepository {
  MemberProfilesRepository(Dio dio)
      : _col = PbCollection(dio, 'member_profiles');

  final PbCollection _col;

  Future<MemberProfile?> byUser(String userId) async {
    final page = await _col.list(
      map: MemberProfile.fromJson,
      page: 1,
      perPage: 1,
      filter: 'user="$userId"',
    );
    return page.items.isEmpty ? null : page.items.first;
  }

  Future<MemberProfile> upsert({
    required String userId,
    required String phone,
    required String birthDate,
    required String notes,
  }) async {
    final existing = await byUser(userId);
    final body = {
      'user': userId,
      'phone': phone,
      'birthDate': birthDate,
      'notes': notes,
    };
    if (existing == null) {
      return _col.create(body, map: MemberProfile.fromJson);
    }
    return _col.update(existing.id, body, map: MemberProfile.fromJson);
  }
}
