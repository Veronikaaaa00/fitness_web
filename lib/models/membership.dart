class Membership {
  const Membership({
    required this.id,
    required this.memberId,
    required this.planId,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.memberName = '',
    this.planTitle = '',
    this.deleted = false,
  });

  final String id;
  final String memberId;
  final String planId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final String memberName;
  final String planTitle;
  final bool deleted;

  bool get isActive =>
      status == 'active' && endsAt.isAfter(DateTime.now().subtract(const Duration(days: 1)));

  factory Membership.fromJson(Map<String, dynamic> json) {
    final expand = json['expand'] is Map
        ? Map<String, dynamic>.from(json['expand'] as Map)
        : const <String, dynamic>{};
    final member = expand['member'] is Map
        ? Map<String, dynamic>.from(expand['member'] as Map)
        : null;
    final plan = expand['plan'] is Map
        ? Map<String, dynamic>.from(expand['plan'] as Map)
        : null;

    return Membership(
      id: '${json['id'] ?? ''}',
      memberId: '${json['member'] ?? ''}',
      planId: '${json['plan'] ?? ''}',
      startsAt: DateTime.tryParse('${json['startsAt'] ?? ''}')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endsAt: DateTime.tryParse('${json['endsAt'] ?? ''}')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: '${json['status'] ?? ''}',
      memberName: '${member?['name'] ?? ''}',
      planTitle: '${plan?['title'] ?? ''}',
      deleted: json['deleted'] == true,
    );
  }
}
