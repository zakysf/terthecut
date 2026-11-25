import 'package:flutter/foundation.dart';
import '../models/reward.dart';
import '../models/reward_redemption.dart';
import '../models/point_ledger.dart';
import '../services/loyalty_service.dart';
import '../services/notification_service.dart';
import 'auth_controller.dart';

/// Singleton controller sistem loyalitas, reward, dompet voucher, dan mutasi poin.
class LoyaltyController extends ChangeNotifier {
  static final LoyaltyController _instance = LoyaltyController._internal();
  factory LoyaltyController() => _instance;
  LoyaltyController._internal();

  final LoyaltyService _loyaltyService = LoyaltyService();

  List<Reward> rewards = [];
  List<RewardRedemption> myVouchers = [];
  List<PointLedgerEntry> pointLedger = [];

  bool isLoading = false;
  bool isRedeeming = false;
  bool isUsingVoucher = false;
  String errorMessage = '';

  List<RewardRedemption> get activeVouchers =>
      myVouchers.where((v) => v.isUsable).toList();

  List<RewardRedemption> get historyVouchers =>
      myVouchers.where((v) => !v.isUsable).toList();

  int get activeCount => activeVouchers.length;
  int get historyCount => historyVouchers.length;

  /// Memuat katalog reward, dompet voucher, dan mutasi poin.
  Future<void> loadLoyaltyData() async {
    final authController = AuthController();
    await authController.refreshProfile();
    final customerId = authController.currentProfile?.id ?? 'demo-user-1';

    isLoading = true;
    notifyListeners();
    try {
      final fetchedRewards = await _loyaltyService.fetchRewards();
      final fetchedVouchers = await _loyaltyService.fetchCustomerVouchers(
        customerId,
      );
      final fetchedLedger = await _loyaltyService.fetchCustomerPointLedger(
        customerId,
      );

      rewards = fetchedRewards;
      myVouchers = fetchedVouchers;
      pointLedger = fetchedLedger;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Eksekusi penukaran poin pelanggan dengan reward (US-12).
  /// Mengembalikan [RewardRedemption] jika berhasil, atau `null` jika gagal.
  Future<RewardRedemption?> executeRedeemReward(Reward reward) async {
    final authController = AuthController();
    final profile = authController.currentProfile;
    if (profile == null) {
      errorMessage = 'Silakan masuk ke akun Anda terlebih dahulu.';
      notifyListeners();
      return null;
    }

    if (profile.pointsBalance < reward.pointsCost) {
      errorMessage =
          'Saldo poin Anda saat ini (${profile.pointsBalance} Pts) belum mencapai ${reward.pointsCost} Pts untuk menukarkan reward ini.';
      notifyListeners();
      return null;
    }

    isRedeeming = true;
    errorMessage = '';
    notifyListeners();

    try {
      final redemption = await _loyaltyService.redeemReward(
        profile: profile,
        reward: reward,
      );

      final updatedProfile = profile.copyWith(
        pointsBalance: profile.pointsBalance - reward.pointsCost,
      );
      authController.updateCurrentProfile(updatedProfile);

      await NotificationService().createNotification(
        userId: profile.id,
        title: 'Penukaran Reward Berhasil',
        message:
            'Voucher "${reward.name}" berhasil ditukarkan (${reward.pointsCost} Pts).',
        type: 'loyalty',
      );

      await loadLoyaltyData();
      return redemption;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      isRedeeming = false;
      notifyListeners();
    }
  }

  /// Eksekusi pemakaian voucher dengan Optimistic UI (US-13).
  Future<bool> confirmUseVoucher(RewardRedemption voucher) async {
    if (!voucher.isUsable) {
      errorMessage =
          'Voucher ini sudah pernah digunakan atau telah melewati batas kedaluwarsa.';
      notifyListeners();
      return false;
    }

    if (isUsingVoucher) return false;
    isUsingVoucher = true;
    errorMessage = '';
    notifyListeners();

    try {
      // 1. Optimistic UI update: langsung ubah status lokal agar UI berganti seketika
      final cleanCode = voucher.voucherCode.trim().toUpperCase();
      final idx = myVouchers.indexWhere(
        (v) => v.voucherCode.trim().toUpperCase() == cleanCode,
      );
      if (idx != -1) {
        myVouchers[idx] = myVouchers[idx].copyWith(status: 'used');
        notifyListeners();
      }

      // 2. Kirim update ke service database
      await _loyaltyService.useVoucher(voucher.voucherCode);

      // 3. Muat ulang data terbaru dari backend
      await loadLoyaltyData();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      isUsingVoucher = false;
      notifyListeners();
    }
  }

  void clearSession() {
    myVouchers = [];
    pointLedger = [];
    errorMessage = '';
    notifyListeners();
  }
}
