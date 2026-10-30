class ActivityType {
  const ActivityType({
    required this.id,
    required this.name,
    this.description = '',
    this.deleted = false,
  });

  final String id;
  final String name;
  final String description;
  final bool deleted;

  factory ActivityType.fromJson(Map<String, dynamic> json) => ActivityType(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        description: '${json['description'] ?? ''}',
        deleted: json['deleted'] == true,
      );
}
