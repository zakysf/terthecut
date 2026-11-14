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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Obx(
              () => TabBar(
                labelColor: AppColors.ink,
                unselectedLabelColor: AppColors.inkSoft,
                indicatorColor: AppColors.gold,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                tabs: [
                  Tab(text: 'Voucher Aktif (${_controller.activeCount})'),
                  Tab(text: 'Riwayat (${_controller.historyCount})'),
                ],
              ),
            ),
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
        itemCount: vouchers.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildOverviewBanner(vouchers.length, isActiveTab);
          }
          final v = vouchers[index - 1];
          return _buildVoucherCard(v, isActiveTab);
        },
      ),
    );
  }

  Widget _buildOverviewBanner(int count, bool isActiveTab) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Icon(
            isActiveTab ? Icons.confirmation_num_outlined : Icons.history,
            size: 18,
            color: isActiveTab ? AppColors.gold : AppColors.inkSoft,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isActiveTab ? 'Tersedia: $count Voucher Aktif' : 'Total Riwayat: $count Voucher',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
          if (isActiveTab) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Get.toNamed('/rewards'),
              child: Text(
                '+ Tukar Lagi',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoucherCard(RewardRedemption voucher, bool isActive) {
    final bool canUse = isActive && voucher.isUsable;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Nama Reward & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: canUse
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.hairline,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    voucher.statusLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: canUse ? AppColors.success : AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
            if (voucher.rewardDescription != null && voucher.rewardDescription!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                voucher.rewardDescription!,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
              ),
            ],
            const Divider(height: 24, color: AppColors.hairline),

            // 2. Kode Voucher Box: Desain Anti-Overflow
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KODE VOUCHER',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            voucher.voucherCode,
                            style: const TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: AppColors.inkSoft),
                    tooltip: 'Salin Kode',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: voucher.voucherCode));
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
                ],
              ),
            ),

            // 3. Tombol Utama "GUNAKAN DI KASIR" (Hanya untuk Voucher Aktif)
            if (canUse) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 15),
                  label: const Text(
                    'GUNAKAN DI KASIR',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.paper,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _controller.useVoucher(voucher),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 4. Footer: Masa Berlaku & Link Reservasi (Anti-Overflow)
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 13, color: AppColors.inkSoft),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          's.d. ${voucher.formattedExpiry}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkSoft),
                        ),
                      ),
                    ],
                  ),
                ),
                if (canUse)
                  GestureDetector(
                    onTap: () => Get.toNamed('/booking-wizard'),
                    child: Text(
                      'Pakai Reservasi ->',
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
