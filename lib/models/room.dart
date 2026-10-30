class Room {
  const Room({
    required this.id,
    required this.name,
    required this.capacity,
    this.description = '',
    this.deleted = false,
  });

  final String id;
  final String name;
  final int capacity;
  final String description;
  final bool deleted;

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
        description: '${json['description'] ?? ''}',
        deleted: json['deleted'] == true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'capacity': capacity,
        'description': description,
        'deleted': deleted,
      };

  Room copyWith({
    String? name,
    int? capacity,
    String? description,
    bool? deleted,
  }) =>
      Room(
        id: id,
        name: name ?? this.name,
        capacity: capacity ?? this.capacity,
        description: description ?? this.description,
        deleted: deleted ?? this.deleted,
      );
}
