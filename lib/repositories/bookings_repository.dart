import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/pb_client.dart';
import '../models/booking.dart';
import '../models/fitness_class.dart';
import '../models/page_result.dart';
import 'pb_collection.dart';

class BookingsRepository {
  BookingsRepository(Dio dio)
      : _col = PbCollection(dio, 'bookings'),
        _classes = PbCollection(dio, 'classes'),
        _memberships = PbCollection(dio, 'memberships'),
        _trainers = PbCollection(dio, 'trainers');

  final PbCollection _col;
  final PbCollection _classes;
  final PbCollection _memberships;
  final PbCollection _trainers;

  /// Nested expand по relation fitnessClass.
  static const expand =
      'fitnessClass,fitnessClass.room,fitnessClass.trainer,fitnessClass.activityType,member';

  Future<PageResult<Booking>> listMine({
    required String memberId,
    int page = 1,
    int perPage = 20,
  }) {
    return _col.list(
      map: Booking.fromJson,
      page: page,
      perPage: perPage,
      filter:
          'member="$memberId" && deleted=false && (status="confirmed" || status="attended" || status="noShow")',
      sort: '-id',
      expand: expand,
    );
  }

  /// Записи на занятия тренера (по user id тренера).
  Future<PageResult<Booking>> listForTrainerUser({
    required String userId,
    int page = 1,
    int perPage = 20,
  }) async {
    final trainers = await _trainers.list(
      map: (j) => j,
      page: 1,
      perPage: 1,
      filter: 'user="$userId" && deleted=false',
    );
    if (trainers.items.isEmpty) {
      return PageResult.empty(page: page, perPage: perPage);
    }
    final trainerId = '${trainers.items.first['id']}';
    return _col.list(
      map: Booking.fromJson,
      page: page,
      perPage: perPage,
      filter:
          'fitnessClass.trainer="$trainerId" && deleted=false && status="confirmed"',
      sort: '-id',
      expand: expand,
    );
  }

  Future<PageResult<Booking>> listForClass({
    required String classId,
    int page = 1,
    int perPage = 50,
  }) {
    return _col.list(
      map: Booking.fromJson,
      page: page,
      perPage: perPage,
      filter:
          'fitnessClass="$classId" && deleted=false && status="confirmed"',
      sort: '-id',
      expand: expand,
    );
  }

  /// Запись с проверками: абонемент, места, пересечение по времени.
  Future<Booking> book({
    required String memberId,
    required String classId,
  }) =>
      guard(() async {
        final fitnessClass = await _classes.getOne(
          classId,
          map: FitnessClass.fromJson,
          expand: 'room,trainer,activityType',
        );

        if (fitnessClass.cancelled || fitnessClass.deleted) {
          throw const ConflictException('Занятие недоступно');
        }
        if (fitnessClass.isFull) {
          throw const ConflictException('Нет свободных мест');
        }
        if (fitnessClass.startsAt.isBefore(DateTime.now())) {
          throw const ConflictException('Занятие уже началось');
        }

        await _ensureActiveMembership(memberId);
        await _ensureNoOverlap(memberId, fitnessClass);
        await _ensureNotAlreadyBooked(memberId, classId);

        final booking = await _col.create(
          {
            'member': memberId,
            'fitnessClass': classId,
            'status': BookingStatus.confirmed.name,
            'deleted': false,
          },
          map: Booking.fromJson,
        );

        // Счётчик мест — best effort: у member часто нет updateRule на classes
        // (PB отвечает 404), запись при этом уже создана.
        try {
          await _classes.update(
            classId,
            {'bookedCount': fitnessClass.bookedCount + 1},
            map: FitnessClass.fromJson,
          );
        } catch (_) {}

        return booking;
      });

  Future<Booking> cancel({
    required String bookingId,
    required String classId,
  }) =>
      guard(() async {
        final booking = await _col.update(
          bookingId,
          {'status': BookingStatus.cancelled.name},
          map: Booking.fromJson,
        );

        if (classId.isNotEmpty) {
          try {
            final fitnessClass = await _classes.getOne(
              classId,
              map: FitnessClass.fromJson,
            );
            final next =
                (fitnessClass.bookedCount - 1).clamp(0, fitnessClass.capacity);
            await _classes.update(
              classId,
              {'bookedCount': next},
              map: FitnessClass.fromJson,
            );
          } catch (_) {
            // счётчик мест — best effort
          }
        }

        return booking;
      });

  Future<void> _ensureActiveMembership(String memberId) async {
    final day = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final result = await _memberships.list(
      map: (j) => j,
      page: 1,
      perPage: 1,
      filter:
          'member="$memberId" && deleted=false && status="active" && endsAt>="$day"',
    );
    if (result.items.isEmpty) {
      throw const ConflictException(
        'Нужен активный абонемент, чтобы записаться',
      );
    }
  }

  Future<void> _ensureNotAlreadyBooked(String memberId, String classId) async {
    final result = await _col.list(
      map: Booking.fromJson,
      page: 1,
      perPage: 1,
      filter:
          'member="$memberId" && fitnessClass="$classId" && deleted=false && status="confirmed"',
    );
    if (result.items.isNotEmpty) {
      throw const ConflictException('Вы уже записаны на это занятие');
    }
  }

  Future<void> _ensureNoOverlap(
    String memberId,
    FitnessClass target,
  ) async {
    final existing = await _col.list(
      map: Booking.fromJson,
      page: 1,
      perPage: 100,
      filter: 'member="$memberId" && deleted=false && status="confirmed"',
      expand: 'fitnessClass',
    );
    final now = DateTime.now();
    for (final b in existing.items) {
      final other = b.fitnessClass;
      if (other == null) continue;
      // Прошедшие занятия не блокируют новую запись.
      if (!other.endsAt.isAfter(now)) continue;
      final overlaps = target.startsAt.isBefore(other.endsAt) &&
          target.endsAt.isAfter(other.startsAt);
      if (overlaps) {
        throw ConflictException(
          'Пересечение с занятием «${other.title}»',
        );
      }
    }
  }

}
