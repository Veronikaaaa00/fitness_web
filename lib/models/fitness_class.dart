class FitnessClass {
  const FitnessClass({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.bookedCount,
    this.roomId = '',
    this.trainerId = '',
    this.activityTypeId = '',
    this.roomName = '',
    this.trainerName = '',
    this.activityName = '',
    this.cancelled = false,
    this.deleted = false,
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final int capacity;
  final int bookedCount;
  final String roomId;
  final String trainerId;
  final String activityTypeId;
  final String roomName;
  final String trainerName;
  final String activityName;
  final bool cancelled;
  final bool deleted;

  int get seatsLeft => (capacity - bookedCount).clamp(0, capacity);
  bool get isFull => seatsLeft <= 0;

  factory FitnessClass.fromJson(Map<String, dynamic> json) {
    final expand = json['expand'] is Map
        ? Map<String, dynamic>.from(json['expand'] as Map)
        : const <String, dynamic>{};
    final room = expand['room'] is Map
        ? Map<String, dynamic>.from(expand['room'] as Map)
        : null;
    final trainer = expand['trainer'] is Map
        ? Map<String, dynamic>.from(expand['trainer'] as Map)
        : null;
    final activity = expand['activityType'] is Map
        ? Map<String, dynamic>.from(expand['activityType'] as Map)
        : null;

    return FitnessClass(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      startsAt: DateTime.tryParse('${json['startsAt'] ?? ''}')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endsAt: DateTime.tryParse('${json['endsAt'] ?? ''}')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      bookedCount: (json['bookedCount'] as num?)?.toInt() ?? 0,
      roomId: '${json['room'] ?? ''}',
      trainerId: '${json['trainer'] ?? ''}',
      activityTypeId: '${json['activityType'] ?? ''}',
      roomName: '${room?['name'] ?? ''}',
      trainerName: '${trainer?['fullName'] ?? trainer?['name'] ?? ''}',
      activityName: '${activity?['name'] ?? ''}',
      cancelled: json['cancelled'] == true,
      deleted: json['deleted'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
        'capacity': capacity,
        'bookedCount': bookedCount,
        'room': roomId,
        'trainer': trainerId,
        'activityType': activityTypeId,
        'cancelled': cancelled,
        'deleted': deleted,
      };
}
