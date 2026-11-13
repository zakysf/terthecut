import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../controllers/loyalty_controller.dart';
import '../../models/reward_redemption.dart';

class MyVouchersView extends StatelessWidget {
  MyVouchersView({super.key});

  final LoyaltyController _controller = Get.isRegistered<LoyaltyController>()
      ? Get.find<LoyaltyController>()
      : Get.put(LoyaltyController());

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadLoyaltyData();
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          title: Text(
            'DOMPET VOUCHER',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.ink,
            unselectedLabelColor: AppColors.inkSoft,
            indicatorColor: AppColors.gold,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'Voucher Aktif'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: SafeArea(
          child: Obx(() {
            if (_controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.ink),
              );
            }

            final active = _controller.activeVouchers;
            final history = _controller.historyVouchers;

            return TabBarView(
              children: [
                _buildVoucherList(active, isActiveTab: true),
                _buildVoucherList(history, isActiveTab: false),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildVoucherList(
    List<RewardRedemption> vouchers, {
    required bool isActiveTab,
  }) {
    if (vouchers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActiveTab ? Icons.card_giftcard_outlined : Icons.history,
                size: 48,
                color: AppColors.inkSoft.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                isActiveTab
                    ? 'Belum Ada Voucher Aktif'
                    : 'Belum Ada Riwayat Voucher',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isActiveTab
                    ? 'Kumpulkan poin dari setiap kunjungan dan tukarkan dengan voucher diskon atau perawatan gratis.'
                    : 'Voucher yang telah Anda gunakan atau telah melewati masa berlaku 30 hari akan tampil di sini.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                ),
              ),
              if (isActiveTab) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Get.toNamed('/rewards'),
                  child: const Text('LIHAT KATALOG REWARD'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _controller.loadLoyaltyData(),
      color: AppColors.ink,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: vouchers.length,
        itemBuilder: (context, index) {
          final v = vouchers[index];
          return _buildVoucherCard(v, isActiveTab);
        },
      ),
    );
  }

  Widget _buildVoucherCard(RewardRedemption voucher, bool isActive) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    voucher.rewardName,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.hairline,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    voucher.statusLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.success : AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
            if (voucher.rewardDescription != null) ...[
              const SizedBox(height: 4),
              Text(
                voucher.rewardDescription!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
            const Divider(height: 24, color: AppColors.hairline),

            // Kode Voucher Eksklusif
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KODE VOUCHER',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voucher.voucherCode,
                      style: const TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                if (isActive)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy, size: 13),
                        label: const Text(
                          'SALIN',
                          style: TextStyle(fontSize: 10),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: voucher.voucherCode),
                          );
                          Get.snackbar(
                            'Kode Disalin',
                            'Kode voucher ${voucher.voucherCode} telah disalin.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.ink,
                            colorText: AppColors.paper,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 14),
                        label: const Text(
                          'GUNAKAN',
                          style: TextStyle(fontSize: 10),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => _controller.useVoucher(voucher),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 13,
                      color: AppColors.inkSoft,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Berlaku s.d. ${voucher.formattedExpiry}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
                if (isActive)
                  GestureDetector(
                    onTap: () {
                      Get.toNamed('/booking-wizard');
                    },
                    child: Text(
                      'Pakai Saat Reservasi ->',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
