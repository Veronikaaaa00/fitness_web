import 'package:dio/dio.dart';

import '../core/pb_client.dart';
import '../models/page_result.dart';

/// Базовый CRUD к коллекции PocketBase.
class PbCollection {
  PbCollection(this._dio, this.collection);

  final Dio _dio;
  final String collection;

  String get _base => '/collections/$collection/records';

  Future<PageResult<T>> list<T>({
    required T Function(Map<String, dynamic>) map,
    int page = 1,
    int perPage = 20,
    String? filter,
    String? sort,
    String? expand,
  }) =>
      guard(() async {
        final response = await _dio.get(
          _base,
          queryParameters: {
            'page': page,
            'perPage': perPage,
            if (filter != null && filter.isNotEmpty) 'filter': filter,
            if (sort != null && sort.isNotEmpty) 'sort': sort,
            if (expand != null && expand.isNotEmpty) 'expand': expand,
          },
        );
        return PageResult.fromPocketBase(
          Map<String, dynamic>.from(response.data as Map),
          map,
        );
      });

  Future<T> getOne<T>(
    String id, {
    required T Function(Map<String, dynamic>) map,
    String? expand,
  }) =>
      guard(() async {
        final response = await _dio.get(
          '$_base/$id',
          queryParameters: {
            if (expand != null && expand.isNotEmpty) 'expand': expand,
          },
        );
        return map(Map<String, dynamic>.from(response.data as Map));
      });

  Future<T> create<T>(
    Map<String, dynamic> body, {
    required T Function(Map<String, dynamic>) map,
  }) =>
      guard(() async {
        final response = await _dio.post(_base, data: body);
        return map(Map<String, dynamic>.from(response.data as Map));
      });

  Future<T> update<T>(
    String id,
    Map<String, dynamic> body, {
    required T Function(Map<String, dynamic>) map,
  }) =>
      guard(() async {
        final response = await _dio.patch('$_base/$id', data: body);
        return map(Map<String, dynamic>.from(response.data as Map));
      });

  Future<void> delete(String id) => guard(() async {
        await _dio.delete('$_base/$id');
      });
}
