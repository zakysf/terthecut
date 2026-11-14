import 'package:flutter_test/flutter_test.dart';
import 'package:terthecut/models/promotion.dart';
import 'package:terthecut/services/feedback_service.dart';
import 'package:terthecut/services/promotion_service.dart';
import 'package:terthecut/services/auth_service.dart';
import 'package:terthecut/services/notification_service.dart';

void main() {
  group('Sprint 4: Feedback, Segmented Promos, Customer Lookup & In-App Notifications', () {
    final feedbackService = FeedbackService();
    final promotionService = PromotionService();
    final authService = AuthService();
    final notificationService = NotificationService();

    // ------------------------------------------------------------------------
    // US-14 & US-15: Formulir Kritik & Saran (Tanpa Bintang) & Tampilan Admin
    // ------------------------------------------------------------------------
    test('US-14: Customer successfully submits feedback without star ratings', () async {
      final feedback = await feedbackService.submitFeedback(
        userId: 'cust-test-1',
        userName: 'Budi Santoso',
        userPhone: '081234567890',
        category: 'Pelayanan',
        message: 'Pelayanan kapster sangat ramah dan potongan rapi.',
      );

      expect(feedback.id, isNotEmpty);
      expect(feedback.userName, 'Budi Santoso');
      expect(feedback.category, 'Pelayanan');
      expect(feedback.message, contains('ramah dan potongan rapi'));
    });

    test('US-15: Admin fetches feedback list strictly in read-only format without star requirements', () async {
      final list = await feedbackService.getFeedbacks();

      expect(list, isNotEmpty);
      final first = list.first;
      expect(first.userName, isNotEmpty);
      expect(first.category, isNotEmpty);
      expect(first.message, isNotEmpty);
    });

    // ------------------------------------------------------------------------
    // US-16 & US-17: Segmented Promotions & Admin Promo Full CRUD
    // ------------------------------------------------------------------------
    test('US-16: Promotion tier eligibility correctly segments customers', () {
      final promoAll = Promotion(
        id: 'p-all',
        title: 'Diskon Hari Pahlawan',
        description: 'Semua member hemat 10%',
        discountPercent: 10,
        targetTier: 'all',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
      );

      final promoGold = Promotion(
        id: 'p-gold',
        title: 'VIP Gold Exclusive',
        description: 'Khusus member Gold',
        discountPercent: 25,
        targetTier: 'gold',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
      );

      // Promo 'all' berlaku untuk Bronze, Silver, Gold
      expect(promoAll.isEligibleForTier('Bronze'), isTrue);
      expect(promoAll.isEligibleForTier('Silver'), isTrue);
      expect(promoAll.isEligibleForTier('Gold'), isTrue);
      expect(promoAll.isEligibleForTier(null), isTrue);

      // Promo 'gold' hanya berlaku untuk member Gold
      expect(promoGold.isEligibleForTier('Gold'), isTrue);
      expect(promoGold.isEligibleForTier('Bronze'), isFalse);
      expect(promoGold.isEligibleForTier('Silver'), isFalse);
      expect(promoGold.isEligibleForTier(null), isFalse);
    });

    test('US-16: Promotion validity period checks current date', () {
      final activePromo = Promotion(
        id: 'p-active',
        title: 'Promo Aktif',
        description: 'Sedang berjalan',
        discountPercent: 15,
        targetTier: 'all',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 2)),
      );

      final expiredPromo = Promotion(
        id: 'p-expired',
        title: 'Promo Kadaluarsa',
        description: 'Sudah lewat',
        discountPercent: 20,
        targetTier: 'all',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().subtract(const Duration(days: 2)),
      );

      expect(activePromo.isValidNow, isTrue);
      expect(expiredPromo.isValidNow, isFalse);
    });

    test('US-17: Admin Promo CRUD (Create, Read, Update, Delete)', () async {
      // 1. CREATE
      final newPromo = await promotionService.createPromotion(
        title: 'Promo Diskon Kilat',
        description: 'Diskon 25% untuk member Silver',
        discountPercent: 25,
        targetTier: 'silver',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 14)),
      );

      expect(newPromo.id, isNotEmpty);
      expect(newPromo.title, 'Promo Diskon Kilat');
      expect(newPromo.discountPercent, 25);
      expect(newPromo.targetTier, 'silver');

      // 2. READ
      final allPromos = await promotionService.getAllPromotions();
      expect(allPromos.any((p) => p.id == newPromo.id), isTrue);

      // 3. UPDATE
      final updatedPromo = newPromo.copyWith(
        title: 'Promo Diskon Kilat (Updated)',
        discountPercent: 30,
        targetTier: 'gold',
      );
      final updateSuccess = await promotionService.updatePromotion(updatedPromo);
      expect(updateSuccess, isTrue);

      final recheckList = await promotionService.getAllPromotions();
      final fetched = recheckList.firstWhere((p) => p.id == newPromo.id);
      expect(fetched.title, 'Promo Diskon Kilat (Updated)');
      expect(fetched.discountPercent, 30);
      expect(fetched.targetTier, 'gold');

      // 4. DELETE
      final deleteSuccess = await promotionService.deletePromotion(newPromo.id);
      expect(deleteSuccess, isTrue);

      final afterDelete = await promotionService.getAllPromotions();
      expect(afterDelete.any((p) => p.id == newPromo.id), isFalse);
    });

    // ------------------------------------------------------------------------
    // US-20: Pencarian Cepat Data Pelanggan oleh Kasir
    // ------------------------------------------------------------------------
    test('US-20: Cashier searches customer by phone query and receives matched profiles', () async {
      // Mock profiles include Dimas (081234567890)
      final results = await authService.searchCustomers('0812');
      expect(results, isNotEmpty);
      expect(results.every((p) => p.role == 'customer'), isTrue);
      expect(results.any((p) => (p.phone ?? '').contains('0812')), isTrue);
    });

    test('US-20: Cashier search filters out admin accounts strictly', () async {
      final results = await authService.searchCustomers('admin');
      // Tidak boleh menampilkan user bertipe admin
      expect(results.any((p) => p.role == 'admin'), isFalse);
    });

    // ------------------------------------------------------------------------
    // US-21: Riwayat Notifikasi In-App
    // ------------------------------------------------------------------------
    test('US-21: System triggers in-app notification and marks as read', () async {
      const testUserId = 'test-cust-notif-1';

      // Buat notifikasi
      final notif = await notificationService.createNotification(
        userId: testUserId,
        title: 'Booking Dikonfirmasi',
        message: 'Jadwal reservasi Anda di Cabang Tajem telah berhasil dikonfirmasi.',
        type: 'booking',
      );

      expect(notif.id, isNotEmpty);
      expect(notif.isRead, isFalse);
      expect(notif.type, 'booking');

      // Ambil daftar notifikasi user
      final list = await notificationService.getNotifications(testUserId);
      expect(list.any((n) => n.id == notif.id), isTrue);

      // Tandai dibaca
      await notificationService.markAsRead(notif.id);

      final recheckList = await notificationService.getNotifications(testUserId);
      final readNotif = recheckList.firstWhere((n) => n.id == notif.id);
      expect(readNotif.isRead, isTrue);
    });
  });
}
