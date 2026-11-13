import 'package:flutter_test/flutter_test.dart';
import 'package:terthecut/models/barber.dart';
import 'package:terthecut/services/booking_service.dart';

void main() {
  group('Booking Persistence & Simplified Cashier Workflow', () {
    final bookingService = BookingService();

    final testBarbers = [
      Barber(id: 'barber-t1', branchId: 'br-t1', name: 'Rian Pratama', sortOrder: 1),
      Barber(id: 'barber-t2', branchId: 'br-t1', name: 'Dimas Setiawan', sortOrder: 2),
    ];

    test('Created booking persists and appears in customer history', () async {
      final now = DateTime.now();
      final scheduleDate = DateTime(now.year, now.month, now.day + 1, 14, 0);

      final created = await bookingService.createBooking(
        customerId: 'cust-persistent-101',
        customerName: 'Ahmad Dahlan',
        customerPhone: '081234567899',
        branchId: 'br-t1',
        branchName: 'Cabang Warungboto',
        branchAddress: 'Jl. Prof. DR. Soepomo SH No. 55',
        branchBarbers: testBarbers,
        serviceId: 'svc-t1',
        serviceName: 'Premium Haircut',
        servicePrice: 35000,
        servicePoints: 10,
        durationHours: 1,
        startsAt: scheduleDate,
      );

      expect(created.code.startsWith('TTC-'), isTrue);
      expect(created.customerName, equals('Ahmad Dahlan'));

      // Check customer bookings history
      final customerBookings = await bookingService.fetchCustomerBookings('cust-persistent-101');
      expect(customerBookings.isNotEmpty, isTrue);
      expect(customerBookings.any((b) => b.code == created.code), isTrue);
      final found = customerBookings.firstWhere((b) => b.code == created.code);
      expect(found.serviceName, equals('Premium Haircut'));
      expect(found.branchName, equals('Cabang Warungboto'));
    });

    test('Created booking appears in Admin daily schedule with customer details', () async {
      final now = DateTime.now();
      final scheduleDate = DateTime(now.year, now.month, now.day + 1, 15, 0);

      final created = await bookingService.createBooking(
        customerId: 'cust-admin-check-102',
        customerName: 'Budi Santoso',
        customerPhone: '081987654321',
        branchId: 'br-t1',
        branchName: 'Cabang Warungboto',
        branchAddress: 'Jl. Prof. DR. Soepomo SH No. 55',
        branchBarbers: testBarbers,
        serviceId: 'svc-t1',
        serviceName: 'Signature VIP Haircut',
        servicePrice: 65000,
        servicePoints: 10,
        durationHours: 1,
        startsAt: scheduleDate,
      );

      // Check admin schedule
      final adminSchedule = await bookingService.fetchAdminDailySchedule(
        branchId: 'br-t1',
        date: scheduleDate,
      );

      expect(adminSchedule.isNotEmpty, isTrue);
      final adminBooking = adminSchedule.firstWhere((b) => b.code == created.code);
      expect(adminBooking.customerName, equals('Budi Santoso'));
      expect(adminBooking.customerPhone, equals('081987654321'));
      expect(adminBooking.status, equals('confirmed'));
    });

    test('Cashier completes booking directly without needing mark-arrived step', () async {
      final now = DateTime.now();
      final scheduleDate = DateTime(now.year, now.month, now.day + 1, 16, 0);

      final created = await bookingService.createBooking(
        customerId: 'cust-complete-103',
        customerName: 'Chandra Wijaya',
        customerPhone: '081112223334',
        branchId: 'br-t1',
        branchName: 'Cabang Warungboto',
        branchAddress: 'Jl. Prof. DR. Soepomo SH No. 55',
        branchBarbers: testBarbers,
        serviceId: 'svc-t1',
        serviceName: 'Premium Haircut',
        servicePrice: 35000,
        servicePoints: 10,
        durationHours: 1,
        startsAt: scheduleDate,
      );

      // Directly mark completed by cashier
      final completed = await bookingService.completeBooking(booking: created);
      expect(completed.status, equals('completed'));
      expect(completed.completedAt, isNotNull);

      // Check history
      final history = await bookingService.fetchCustomerBookings('cust-complete-103');
      final completedInHistory = history.firstWhere((b) => b.code == created.code);
      expect(completedInHistory.status, equals('completed'));
    });
  });
}

