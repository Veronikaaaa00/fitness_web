class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.quantity,
    this.deleted = false,
  });

  final String id;
  final String name;
  final int quantity;
  final bool deleted;

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        deleted: json['deleted'] == true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'deleted': deleted,
      };
}
