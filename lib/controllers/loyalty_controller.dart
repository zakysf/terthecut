import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/theme.dart';
import '../models/reward.dart';
import '../models/reward_redemption.dart';
import '../models/point_ledger.dart';
import '../services/loyalty_service.dart';
import 'auth_controller.dart';

class LoyaltyController extends GetxController {
  final LoyaltyService _loyaltyService = LoyaltyService();

  final RxList<Reward> rewards = <Reward>[].obs;
  final RxList<RewardRedemption> myVouchers = <RewardRedemption>[].obs;
  final RxList<PointLedgerEntry> pointLedger = <PointLedgerEntry>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isRedeeming = false.obs;

  List<RewardRedemption> get activeVouchers =>
      myVouchers.where((v) => v.isUsable).toList();

  List<RewardRedemption> get historyVouchers =>
      myVouchers.where((v) => !v.isUsable).toList();

  @override
  void onInit() {
    super.onInit();
    loadLoyaltyData();
  }

  /// Memuat katalog reward, dompet voucher, dan mutasi poin
  Future<void> loadLoyaltyData() async {
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);

    await authController.refreshProfile();
    final customerId = authController.currentProfile?.id ?? 'demo-user-1';

    isLoading.value = true;
    try {
      final fetchedRewards = await _loyaltyService.fetchRewards();
      final fetchedVouchers = await _loyaltyService.fetchCustomerVouchers(customerId);
      final fetchedLedger = await _loyaltyService.fetchCustomerPointLedger(customerId);

      rewards.assignAll(fetchedRewards);
      myVouchers.assignAll(fetchedVouchers);
      pointLedger.assignAll(fetchedLedger);
    } finally {
      isLoading.value = false;
    }
  }

  /// Menukarkan poin pelanggan dengan reward (US-12)
  Future<void> redeemReward(Reward reward) async {
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);

    final profile = authController.currentProfile;
    if (profile == null) {
      Get.snackbar('Perhatian', 'Silakan masuk ke akun Anda terlebih dahulu.');
      return;
    }

    if (profile.pointsBalance < reward.pointsCost) {
      Get.defaultDialog(
        title: 'Poin Tidak Cukup',
        middleText:
            'Saldo poin Anda saat ini (${profile.pointsBalance} Pts) belum mencapai ${reward.pointsCost} Pts untuk menukarkan reward ini.',
        textConfirm: 'Mengerti',
        confirmTextColor: AppColors.paper,
        buttonColor: AppColors.ink,
        onConfirm: () => Get.back(),
      );
      return;
    }

    // Dialog Konfirmasi
    Get.defaultDialog(
      title: 'Konfirmasi Penukaran',
      middleText:
          'Apakah Anda yakin ingin menukarkan ${reward.pointsCost} Poin untuk voucher "${reward.name}"?',
      textConfirm: 'Ya, Tukar',
      textCancel: 'Batal',
      confirmTextColor: AppColors.paper,
      buttonColor: AppColors.ink,
      onConfirm: () async {
        Get.back(); // Tutup dialog konfirmasi
        isRedeeming.value = true;

        try {
          final redemption = await _loyaltyService.redeemReward(
            profile: profile,
            reward: reward,
          );

          // Update profil lokal di AuthController
          final updatedProfile = profile.copyWith(
            pointsBalance: profile.pointsBalance - reward.pointsCost,
          );
          authController.updateCurrentProfile(updatedProfile);

          // Refresh data voucher dan mutasi
          await loadLoyaltyData();

          // Tampilkan dialog selamat dengan kode voucher
          Get.dialog(
            Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_giftcard, color: AppColors.gold, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'PENUKARAN BERHASIL!',
                      style: Theme.of(Get.context!).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Voucher ${reward.name} telah diterbitkan dan tersimpan di Dompet Voucher Anda.',
                      textAlign: TextAlign.center,
                      style: Theme.of(Get.context!).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        redemption.voucherCode,
                        style: const TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.0,
                          color: AppColors.paper,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Berlaku hingga: ${redemption.formattedExpiry}',
                      style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.toNamed('/my-vouchers');
                      },
                      child: const Text('BUKA DOMPET VOUCHER'),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('TUTUP'),
                    ),
                  ],
                ),
              ),
            ),
          );
        } catch (e) {
          Get.snackbar('Penukaran Gagal', e.toString().replaceAll('Exception: ', ''));
        } finally {
          isRedeeming.value = false;
        }
      },
    );
  }

  /// Menandai voucher telah digunakan saat pembayaran di kasir
  Future<void> useVoucher(RewardRedemption voucher) async {
    Get.defaultDialog(
      title: 'Gunakan Voucher?',
      middleText:
          'Apakah Anda ingin menggunakan voucher "${voucher.rewardName}" (${voucher.voucherCode}) sekarang?\n\nVoucher yang telah digunakan tidak dapat dibatalkan.',
      textConfirm: 'Ya, Gunakan',
      textCancel: 'Batal',
      confirmTextColor: AppColors.paper,
      buttonColor: AppColors.success,
      onConfirm: () async {
        Get.back();
        try {
          await _loyaltyService.useVoucher(voucher.voucherCode);
          await loadLoyaltyData();
          Get.snackbar(
            'Voucher Digunakan',
            'Voucher ${voucher.voucherCode} telah berhasil ditandai sebagai terpakai.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.ink,
            colorText: AppColors.paper,
            duration: const Duration(seconds: 3),
          );
        } catch (e) {
          Get.snackbar('Gagal', e.toString().replaceAll('Exception: ', ''));
        }
      },
    );
  }
}

