class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.title,
    required this.durationDays,
    required this.price,
    this.description = '',
    this.visitsLimit,
    this.deleted = false,
  });

  final String id;
  final String title;
  final int durationDays;
  final double price;
  final String description;
  final int? visitsLimit;
  final bool deleted;

  factory MembershipPlan.fromJson(Map<String, dynamic> json) => MembershipPlan(
        id: '${json['id'] ?? ''}',
        title: '${json['title'] ?? ''}',
        durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        description: '${json['description'] ?? ''}',
        visitsLimit: (json['visitsLimit'] as num?)?.toInt(),
        deleted: json['deleted'] == true,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'durationDays': durationDays,
        'price': price,
        'description': description,
        if (visitsLimit != null) 'visitsLimit': visitsLimit,
        'deleted': deleted,
      };
}
