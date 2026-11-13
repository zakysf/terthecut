import 'package:flutter_test/flutter_test.dart';
import 'package:terthecut/config/date_format_helper.dart';
import 'package:terthecut/models/barber.dart';
import 'package:terthecut/models/booking.dart';
import 'package:terthecut/services/booking_service.dart';

void main() {
  group('Sprint 2: Booking Engine & Concurrency Tests', () {
    final bookingService = BookingService();

    final testBarbers = [
      Barber(id: 'barber-1', branchId: 'branch-1', name: 'Rian (Warungboto)', sortOrder: 1),
      Barber(id: 'barber-2', branchId: 'branch-1', name: 'Yusuf (Warungboto)', sortOrder: 2),
    ];

    test('US-08: Hourly slots calculated correctly for 1-hour service', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final slots = await bookingService.calculateAvailableSlots(
        branchId: 'branch-1',
        branchBarbers: testBarbers,
        selectedBarberId: null, // Auto-assign
        durationHours: 1,
        date: tomorrow,
      );

      // Dari jam 10 s/d 21 = 12 slot jam bulat
      expect(slots.length, 12);
      expect(slots.first.hour, 10);
      expect(slots.last.hour, 21);

      // Seluruh slot untuk besok harusnya tersedia jika belum ada booking
      for (final slot in slots) {
        expect(slot.isAvailable, isTrue);
      }
    });

    test('US-08: Multi-hour services (3 Hours) cannot start past 19:00', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final slots = await bookingService.calculateAvailableSlots(
        branchId: 'branch-1',
        branchBarbers: testBarbers,
        selectedBarberId: null,
        durationHours: 3, // Layanan 3 jam
        date: tomorrow,
      );

      // Jam 20:00 + 3 = 23:00 (lewat jam tutup 22:00) -> harus tidak tersedia
      final slot20 = slots.firstWhere((s) => s.hour == 20);
      expect(slot20.isAvailable, isFalse);
      expect(slot20.reason, contains('jam tutup'));

      // Jam 21:00 + 3 = 24:00 -> harus tidak tersedia
      final slot21 = slots.firstWhere((s) => s.hour == 21);
      expect(slot21.isAvailable, isFalse);

      // Jam 19:00 + 3 = 22:00 -> pas jam tutup, harus tersedia
      final slot19 = slots.firstWhere((s) => s.hour == 19);
      expect(slot19.isAvailable, isTrue);
    });

    test('US-09: Auto-assign load balances and picks barber with fewest bookings', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final start = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 0);
      final end = start.add(const Duration(hours: 1));

      // Barber 1 sudah punya 1 booking di jam 11:00
      final activeBookings = [
        Booking(
          id: 'bk-mock-1',
          code: 'TTC-111111',
          customerId: 'user-a',
          branchId: 'branch-1',
          branchName: 'Cabang Warungboto',
          branchAddress: 'Jl. Prof DR Soepomo',
          barberId: 'barber-1',
          barberName: 'Rian (Warungboto)',
          serviceId: 'svc-1',
          serviceName: 'Premium Haircut',
          servicePrice: 35000,
          servicePoints: 10,
          durationHours: 1,
          startsAt: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 11, 0),
          endsAt: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 12, 0),
          status: 'confirmed',
        ),
      ];

      // Auto-assign harus memilih Barber 2 karena Barber 1 sudah punya 1 booking
      final selectedBarber = bookingService.selectBestBarberForAutoAssign(
        branchBarbers: testBarbers,
        start: start,
        end: end,
        activeBookings: activeBookings,
      );

      expect(selectedBarber.id, 'barber-2');
      expect(selectedBarber.name, 'Yusuf (Warungboto)');
    });

    test('US-09: Anti-double booking prevents overlapping slots for same barber', () async {
      final targetDate = DateTime.now().add(const Duration(days: 2));
      final startsAt = DateTime(targetDate.year, targetDate.month, targetDate.day, 14, 0);

      // Booking 1 berhasil
      final booking1 = await bookingService.createBooking(
        customerId: 'customer-1',
        branchId: 'branch-1',
        branchName: 'Cabang Warungboto',
        branchAddress: 'Jl. Prof DR Soepomo',
        branchBarbers: testBarbers,
        selectedBarberId: 'barber-1',
        serviceId: 'svc-1',
        serviceName: 'Premium Haircut',
        servicePrice: 35000,
        servicePoints: 10,
        durationHours: 1,
        startsAt: startsAt,
      );

      expect(booking1.code, startsWith('TTC-'));
      expect(booking1.barberId, 'barber-1');

      // Booking 2 mencoba memesan kapster yang sama di jam yang sama -> HARUS DITOLAK
      expect(
        () async => await bookingService.createBooking(
          customerId: 'customer-2',
          branchId: 'branch-1',
          branchName: 'Cabang Warungboto',
          branchAddress: 'Jl. Prof DR Soepomo',
          branchBarbers: testBarbers,
          selectedBarberId: 'barber-1', // Kapster yang sama
          serviceId: 'svc-1',
          serviceName: 'Premium Haircut',
          servicePrice: 35000,
          servicePoints: 10,
          durationHours: 1,
          startsAt: startsAt, // Jam yang sama
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('US-10: Cancellation allowed >= 2 hours before scheduled start', () {
      final now = DateTime.now();

      // Booking 4 jam dari sekarang -> boleh dibatalkan
      final futureBooking = Booking(
        id: 'bk-future',
        code: 'TTC-999999',
        customerId: 'customer-1',
        branchId: 'branch-1',
        branchName: 'Cabang Warungboto',
        branchAddress: 'Jl. Soepomo',
        barberId: 'barber-1',
        barberName: 'Rian',
        serviceId: 'svc-1',
        serviceName: 'Premium Haircut',
        servicePrice: 35000,
        servicePoints: 10,
        durationHours: 1,
        startsAt: now.add(const Duration(hours: 4)),
        endsAt: now.add(const Duration(hours: 5)),
        status: 'confirmed',
      );

      expect(futureBooking.canCancel, isTrue);

      // Booking 1 jam dari sekarang -> TIDAK boleh dibatalkan (< 120 menit)
      final urgentBooking = Booking(
        id: 'bk-urgent',
        code: 'TTC-888888',
        customerId: 'customer-1',
        branchId: 'branch-1',
        branchName: 'Cabang Warungboto',
        branchAddress: 'Jl. Soepomo',
        barberId: 'barber-1',
        barberName: 'Rian',
        serviceId: 'svc-1',
        serviceName: 'Premium Haircut',
        servicePrice: 35000,
        servicePoints: 10,
        durationHours: 1,
        startsAt: now.add(const Duration(minutes: 60)),
        endsAt: now.add(const Duration(minutes: 120)),
        status: 'confirmed',
      );

      expect(urgentBooking.canCancel, isFalse);
    });

    test('IndonesianDateHelper formats dates without LocaleDataException', () {
      final sampleDate = DateTime(2026, 11, 14, 14, 0);
      final sampleEnd = DateTime(2026, 11, 14, 16, 0);

      expect(IndonesianDateHelper.dayLong(sampleDate), 'Sabtu');
      expect(IndonesianDateHelper.dayShort(sampleDate), 'Sab');
      expect(IndonesianDateHelper.monthShort(sampleDate), 'Nov');
      expect(IndonesianDateHelper.formatShort(sampleDate), 'Sabtu, 14 Nov 2026');
      expect(IndonesianDateHelper.formatTimeRange(sampleDate, sampleEnd), '14:00 - 16:00 WIB');
    });
  });
}

