import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Синхронизация page/q/sort и доп. фильтров с query string в URL.
class ListQuery {
  const ListQuery({
    this.page = 1,
    this.q = '',
    this.sort = '',
    this.extra = const {},
  });

  final int page;
  final String q;
  final String sort;
  final Map<String, String> extra;

  factory ListQuery.fromUri(Uri uri, {String defaultSort = ''}) {
    final qp = Map<String, String>.from(uri.queryParameters);
    final page = int.tryParse(qp.remove('page') ?? '') ?? 1;
    final q = qp.remove('q') ?? '';
    final sort = qp.remove('sort') ?? defaultSort;
    return ListQuery(page: page, q: q, sort: sort, extra: qp);
  }

  factory ListQuery.fromContext(
    BuildContext context, {
    String defaultSort = '',
  }) {
    return ListQuery.fromUri(
      GoRouterState.of(context).uri,
      defaultSort: defaultSort,
    );
  }

  void go(BuildContext context, String path) {
    final params = <String, String>{
      if (page > 1) 'page': '$page',
      if (q.trim().isNotEmpty) 'q': q.trim(),
      if (sort.isNotEmpty) 'sort': sort,
      ...extra,
    };
    context.go(Uri(path: path, queryParameters: params).toString());
  }

  ListQuery copyWith({
    int? page,
    String? q,
    String? sort,
    Map<String, String>? extra,
  }) =>
      ListQuery(
        page: page ?? this.page,
        q: q ?? this.q,
        sort: sort ?? this.sort,
        extra: extra ?? this.extra,
      );
}
