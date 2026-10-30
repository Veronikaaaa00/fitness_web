class MemberProfile {
  const MemberProfile({
    required this.id,
    required this.userId,
    this.phone = '',
    this.birthDate = '',
    this.notes = '',
  });

  final String id;
  final String userId;
  final String phone;
  final String birthDate;
  final String notes;

  factory MemberProfile.fromJson(Map<String, dynamic> json) => MemberProfile(
        id: '${json['id'] ?? ''}',
        userId: '${json['user'] ?? ''}',
        phone: '${json['phone'] ?? ''}',
        birthDate: '${json['birthDate'] ?? ''}',
        notes: '${json['notes'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {
        'user': userId,
        'phone': phone,
        'birthDate': birthDate,
        'notes': notes,
      };

  MemberProfile copyWith({
    String? phone,
    String? birthDate,
    String? notes,
  }) =>
      MemberProfile(
        id: id,
        userId: userId,
        phone: phone ?? this.phone,
        birthDate: birthDate ?? this.birthDate,
        notes: notes ?? this.notes,
      );
}
