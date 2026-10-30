class PageResult<T> {
  const PageResult({
    required this.items,
    required this.page,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int perPage;
  final int totalItems;
  final int totalPages;

  factory PageResult.empty({int page = 1, int perPage = 20}) => PageResult(
        items: const [],
        page: page,
        perPage: perPage,
        totalItems: 0,
        totalPages: 0,
      );

  /// Ответ PocketBase: items / totalItems / perPage.
  factory PageResult.fromPocketBase(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) mapItem,
  ) {
    final raw = json['items'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => mapItem(Map<String, dynamic>.from(e)))
            .toList()
        : <T>[];
    return PageResult(
      items: list,
      page: (json['page'] as num?)?.toInt() ?? 1,
      perPage: (json['perPage'] as num?)?.toInt() ?? list.length,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? list.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
