import 'package:flutter_test/flutter_test.dart';
import 'package:terthecut/models/profile.dart';
import 'package:terthecut/models/reward.dart';
import 'package:terthecut/models/booking.dart';
import 'package:terthecut/services/loyalty_service.dart';
import 'package:terthecut/services/booking_service.dart';

void main() {
  group('Sprint 3: Loyalty System, Rewards & Automated Cashier Tests', () {
    final loyaltyService = LoyaltyService();
    final bookingService = BookingService();

    test('US-02: Member tier calculates dynamically based on lifetime points', () {
      final bronzeUser = Profile(id: 'u1', role: 'customer', lifetimePoints: 50);
      expect(bronzeUser.tier, 'Bronze');

      final silverUser = Profile(id: 'u2', role: 'customer', lifetimePoints: 150);
      expect(silverUser.tier, 'Silver');

      final goldUser = Profile(id: 'u3', role: 'customer', lifetimePoints: 350);
      expect(goldUser.tier, 'Gold');
    });

    test('US-12: Reward redemption rejects insufficient points', () async {
      final userPoor = Profile(
        id: 'user-poor',
        role: 'customer',
        pointsBalance: 20, // Hanya punya 20 poin
      );

      final expensiveReward = Reward(
        id: 'rew-3',
        name: 'Gratis Premium Haircut',
        pointsCost: 150,
      );

      expect(
        () async => await loyaltyService.redeemReward(
          profile: userPoor,
          reward: expensiveReward,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('US-12 & US-13: Reward redemption generates unique REW- voucher code and records ledger', () async {
      final userRich = Profile(
        id: 'user-rich',
        role: 'customer',
        pointsBalance: 200,
        lifetimePoints: 200,
      );

      final reward = Reward(
        id: 'rew-1',
        name: 'Diskon Rp 10.000',
        pointsCost: 50,
      );

      final voucher = await loyaltyService.redeemReward(
        profile: userRich,
        reward: reward,
      );

      // Verifikasi format kode voucher REW-XXXXXXXX (US-12)
      expect(voucher.voucherCode, startsWith('REW-'));
      expect(voucher.pointsSpent, 50);
      expect(voucher.status, 'active');
      expect(voucher.isUsable, isTrue);

      // Verifikasi masa berlaku 30 hari (US-13)
      final diffDays = voucher.expiresAt.difference(DateTime.now()).inDays;
      expect(diffDays, inInclusiveRange(29, 31));

      // Verifikasi mutasi poin tercatat di ledger (US-11)
      final ledger = await loyaltyService.fetchCustomerPointLedger('user-rich');
      expect(ledger.any((l) => l.delta == -50 && l.reason == 'redeem'), isTrue);
    });

    test('US-18 & US-19: Admin daily schedule and cashier completion workflow', () async {
      final today = DateTime.now();

      // Buat booking baru
      final newBooking = Booking(
        id: 'bk-cashier-test-1',
        code: 'TTC-777888',
        customerId: 'customer-vip',
        customerName: 'Bagas VIP',
        customerPhone: '08123456789',
        branchId: 'branch-warungboto',
        branchName: 'Cabang Warungboto',
        branchAddress: 'Jl. Soepomo',
        barberId: 'barber-1',
        barberName: 'Rian',
        serviceId: 'svc-vip',
        serviceName: 'Signature VIP Haircut',
        servicePrice: 65000,
        servicePoints: 10,
        durationHours: 1,
        startsAt: DateTime(today.year, today.month, today.day, 13, 0),
        endsAt: DateTime(today.year, today.month, today.day, 14, 0),
        status: 'confirmed',
      );

      // Simpan booking ke mock
      final created = await bookingService.createBooking(
        customerId: newBooking.customerId,
        customerName: newBooking.customerName,
        customerPhone: newBooking.customerPhone,
        branchId: newBooking.branchId,
        branchName: newBooking.branchName,
        branchAddress: newBooking.branchAddress,
        branchBarbers: [],
        selectedBarberId: newBooking.barberId,
        serviceId: newBooking.serviceId,
        serviceName: newBooking.serviceName,
        servicePrice: newBooking.servicePrice,
        servicePoints: newBooking.servicePoints,
        durationHours: newBooking.durationHours,
        startsAt: newBooking.startsAt,
      );

      // 1. Admin melihat jadwal harian cabang (US-18)
      final schedule = await bookingService.fetchAdminDailySchedule(
        branchId: newBooking.branchId,
        date: today,
      );
      expect(schedule.any((b) => b.code == created.code), isTrue);

      // 2. Kasir menandai Datang / Hadir (US-19)
      final markedArrived = await bookingService.markBookingArrived(created.id);
      expect(markedArrived, isTrue);

      // 3. Kasir menandai Selesai & membukukan transaksi secara otomatis (US-19)
      final completed = await bookingService.completeBooking(booking: created);
      expect(completed.status, 'completed');
      expect(completed.completedAt, isNotNull);
    });

    test('US-13: Voucher usage marks voucher as used and prevents reuse', () async {
      final user = Profile(
        id: 'user-voucher-usage',
        role: 'customer',
        pointsBalance: 100,
        lifetimePoints: 100,
      );

      final reward = Reward(
        id: 'rew-1',
        name: 'Diskon Rp 10.000',
        pointsCost: 50,
      );

      final voucher = await loyaltyService.redeemReward(
        profile: user,
        reward: reward,
      );

      expect(voucher.status, 'active');
      expect(voucher.isUsable, isTrue);

      // Gunakan voucher
      final success = await loyaltyService.useVoucher(voucher.voucherCode);
      expect(success, isTrue);

      final updatedVouchers = await loyaltyService.fetchCustomerVouchers('user-voucher-usage');
      final usedVoucher = updatedVouchers.firstWhere((v) => v.voucherCode == voucher.voucherCode);
      expect(usedVoucher.status, 'used');
      expect(usedVoucher.isUsable, isFalse);
      expect(usedVoucher.statusLabel, 'Sudah Dipakai');
    });
  });
}

