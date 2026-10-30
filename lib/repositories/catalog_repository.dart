import 'package:dio/dio.dart';

import '../models/activity_type.dart';
import '../models/app_user.dart';
import '../models/page_result.dart';
import '../models/trainer.dart';
import 'pb_collection.dart';

class CatalogRepository {
  CatalogRepository(Dio dio)
      : _types = PbCollection(dio, 'activity_types'),
        _trainers = PbCollection(dio, 'trainers'),
        _users = PbCollection(dio, 'users');

  final PbCollection _types;
  final PbCollection _trainers;
  final PbCollection _users;

  Future<List<ActivityType>> activityTypes({bool includeDeleted = false}) async {
    final page = await _types.list(
      map: ActivityType.fromJson,
      page: 1,
      perPage: 100,
      filter: includeDeleted ? 'deleted=true' : 'deleted=false',
      sort: 'name',
    );
    return page.items;
  }

  Future<ActivityType> createActivityType(Map<String, dynamic> body) =>
      _types.create(body, map: ActivityType.fromJson);

  Future<ActivityType> updateActivityType(String id, Map<String, dynamic> body) =>
      _types.update(id, body, map: ActivityType.fromJson);

  Future<ActivityType> softDeleteActivityType(String id) =>
      _types.update(id, {'deleted': true}, map: ActivityType.fromJson);

  Future<ActivityType> restoreActivityType(String id) =>
      _types.update(id, {'deleted': false}, map: ActivityType.fromJson);

  Future<void> hardDeleteActivityType(String id) => _types.delete(id);

  Future<int> softDeleteActivityTypesMany(List<String> ids) async {
    var n = 0;
    for (final id in ids) {
      await softDeleteActivityType(id);
      n++;
    }
    return n;
  }

  Future<List<Trainer>> trainers({bool includeDeleted = false}) async {
    final page = await _trainers.list(
      map: Trainer.fromJson,
      page: 1,
      perPage: 100,
      filter: includeDeleted ? 'deleted=true' : 'deleted=false',
      sort: 'fullName',
    );
    return page.items;
  }

  Future<Trainer> createTrainer(Map<String, dynamic> body) =>
      _trainers.create(body, map: Trainer.fromJson);

  Future<Trainer> updateTrainer(String id, Map<String, dynamic> body) =>
      _trainers.update(id, body, map: Trainer.fromJson);

  Future<Trainer> softDeleteTrainer(String id) =>
      _trainers.update(id, {'deleted': true}, map: Trainer.fromJson);

  Future<Trainer> restoreTrainer(String id) =>
      _trainers.update(id, {'deleted': false}, map: Trainer.fromJson);

  Future<void> hardDeleteTrainer(String id) => _trainers.delete(id);

  Future<int> softDeleteTrainersMany(List<String> ids) async {
    var n = 0;
    for (final id in ids) {
      await softDeleteTrainer(id);
      n++;
    }
    return n;
  }

  Future<List<AppUser>> trainerCandidateUsers() async {
    final page = await _users.list(
      map: AppUser.fromJson,
      page: 1,
      perPage: 100,
      filter: 'role="trainer"',
      sort: 'name',
    );
    return page.items;
  }

  Future<Trainer?> trainerByUserId(String userId) async {
    final page = await _trainers.list(
      map: Trainer.fromJson,
      page: 1,
      perPage: 1,
      filter: 'user="$userId" && deleted=false',
    );
    return page.items.isEmpty ? null : page.items.first;
  }

  Future<List<AppUser>> members() async {
    final page = await _users.list(
      map: AppUser.fromJson,
      page: 1,
      perPage: 100,
      filter: '(role="member" || role="admin")',
      sort: 'name',
    );
    return page.items;
  }

  Future<PageResult<AppUser>> usersPage({int page = 1, int perPage = 50}) {
    return _users.list(
      map: AppUser.fromJson,
      page: page,
      perPage: perPage,
      sort: 'name',
    );
  }
}
