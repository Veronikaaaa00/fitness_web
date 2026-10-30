class Trainer {
  const Trainer({
    required this.id,
    required this.userId,
    required this.fullName,
    this.bio = '',
    this.deleted = false,
  });

  final String id;
  final String userId;
  final String fullName;
  final String bio;
  final bool deleted;

  factory Trainer.fromJson(Map<String, dynamic> json) => Trainer(
        id: '${json['id'] ?? ''}',
        userId: '${json['user'] ?? ''}',
        fullName: '${json['fullName'] ?? ''}',
        bio: '${json['bio'] ?? ''}',
        deleted: json['deleted'] == true,
      );
}
