import 'fitness_class.dart';

enum BookingStatus {
  confirmed,
  cancelled,
  attended,
  noShow;

  String get label => switch (this) {
        BookingStatus.confirmed => 'Подтверждена',
        BookingStatus.cancelled => 'Отменена',
        BookingStatus.attended => 'Посещено',
        BookingStatus.noShow => 'Неявка',
      };

  static BookingStatus fromApi(String? value) {
    return BookingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BookingStatus.confirmed,
    );
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.memberId,
    required this.classId,
    required this.status,
    this.created = '',
    this.fitnessClass,
    this.memberName = '',
    this.deleted = false,
  });

  final String id;
  final String memberId;
  final String classId;
  final BookingStatus status;
  final String created;
  final FitnessClass? fitnessClass;
  final String memberName;
  final bool deleted;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final expand = json['expand'] is Map
        ? Map<String, dynamic>.from(json['expand'] as Map)
        : const <String, dynamic>{};

    Map<String, dynamic>? clsRaw;
    if (expand['fitnessClass'] is Map) {
      clsRaw = Map<String, dynamic>.from(expand['fitnessClass'] as Map);
    } else if (expand['class'] is Map) {
      clsRaw = Map<String, dynamic>.from(expand['class'] as Map);
    }

    final member = expand['member'] is Map
        ? Map<String, dynamic>.from(expand['member'] as Map)
        : null;

    return Booking(
      id: '${json['id'] ?? ''}',
      memberId: '${json['member'] ?? ''}',
      classId: '${json['fitnessClass'] ?? json['class'] ?? ''}',
      status: BookingStatus.fromApi('${json['status'] ?? ''}'),
      created: '${json['created'] ?? ''}',
      fitnessClass: clsRaw == null ? null : FitnessClass.fromJson(clsRaw),
      memberName: '${member?['name'] ?? ''}',
      deleted: json['deleted'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'member': memberId,
        'fitnessClass': classId,
        'status': status.name,
        'deleted': deleted,
      };
}
