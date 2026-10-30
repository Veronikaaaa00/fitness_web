import 'package:dio/dio.dart';

import '../models/page_result.dart';
import 'pb_collection.dart';

class ClassEquipmentLink {
  const ClassEquipmentLink({
    required this.id,
    required this.classId,
    required this.equipmentId,
  });

  final String id;
  final String classId;
  final String equipmentId;

  factory ClassEquipmentLink.fromJson(Map<String, dynamic> json) =>
      ClassEquipmentLink(
        id: '${json['id'] ?? ''}',
        classId: '${json['fitnessClass'] ?? json['class'] ?? ''}',
        equipmentId: '${json['equipment'] ?? ''}',
      );
}

class ClassEquipmentRepository {
  ClassEquipmentRepository(Dio dio) : _col = PbCollection(dio, 'class_equipment');

  final PbCollection _col;

  Future<List<ClassEquipmentLink>> forClass(String classId) async {
    final page = await _col.list(
      map: ClassEquipmentLink.fromJson,
      page: 1,
      perPage: 100,
      filter: 'fitnessClass="$classId"',
    );
    return page.items;
  }

  Future<void> sync({
    required String classId,
    required List<String> equipmentIds,
  }) async {
    final existing = await forClass(classId);
    final want = equipmentIds.toSet();
    final have = {for (final e in existing) e.equipmentId: e};

    for (final id in want) {
      if (!have.containsKey(id)) {
        await _col.create(
          {'fitnessClass': classId, 'equipment': id},
          map: ClassEquipmentLink.fromJson,
        );
      }
    }
    for (final entry in have.entries) {
      if (!want.contains(entry.key)) {
        await _col.delete(entry.value.id);
      }
    }
  }

  Future<PageResult<ClassEquipmentLink>> list({int page = 1}) => _col.list(
        map: ClassEquipmentLink.fromJson,
        page: page,
      );
}
