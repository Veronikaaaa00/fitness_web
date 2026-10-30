import 'package:fitness_web/models/fitness_class.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('occupancy / seats', () {
    test('seatsLeft and isFull', () {
      final cls = FitnessClass(
        id: '1',
        title: 'Yoga',
        startsAt: DateTime.now().add(const Duration(days: 1)),
        endsAt: DateTime.now().add(const Duration(days: 1, hours: 1)),
        capacity: 10,
        bookedCount: 10,
      );
      expect(cls.seatsLeft, 0);
      expect(cls.isFull, isTrue);
    });

    test('overlap detection', () {
      final aStart = DateTime(2026, 11, 1, 10);
      final aEnd = DateTime(2026, 11, 1, 11);
      final bStart = DateTime(2026, 11, 1, 10, 30);
      final bEnd = DateTime(2026, 11, 1, 11, 30);
      final overlaps = aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
      expect(overlaps, isTrue);

      final cStart = DateTime(2026, 11, 1, 12);
      final cEnd = DateTime(2026, 11, 1, 13);
      final noOverlap = aStart.isBefore(cEnd) && aEnd.isAfter(cStart);
      expect(noOverlap, isFalse);
    });
  });
}
