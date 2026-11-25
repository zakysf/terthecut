import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../config/ui_helpers.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/loyalty_controller.dart';
import '../../models/reward_redemption.dart';
import '../booking/booking_wizard_view.dart';
import 'reward_catalog_view.dart';

class MyVouchersView extends StatefulWidget {
  final bool showBackButton;
  const MyVouchersView({super.key, this.showBackButton = true});

  @override
  State<MyVouchersView> createState() => _MyVouchersViewState();
}

class _MyVouchersViewState extends State<MyVouchersView> {
  final LoyaltyController _controller = LoyaltyController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadLoyaltyData();
    });
  }

  Future<void> _showUseVoucherDialog(RewardRedemption voucher) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'KASIR WALK-IN & PEMBAYARAN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'TUNJUKKAN KE KASIR',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  voucher.rewardName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        voucher.voucherCode,
                        style: const TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.5,
                          color: AppColors.paper,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Berlaku s.d. ${voucher.formattedExpiry}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.paper.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.accent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tunjukkan kode ini kepada kasir saat pembayaran. Tekan "Konfirmasi Pemakaian" bersama kasir.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text(
                      'KONFIRMASI PEMAKAIAN',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.paper,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _handleConfirmUseVoucher(voucher);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'TUTUP / BATAL',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleConfirmUseVoucher(RewardRedemption voucher) async {
    final ok = await _controller.confirmUseVoucher(voucher);
    if (!mounted) return;
    if (ok) {
      showAppSnackBar(
        context,
        'Voucher ${voucher.voucherCode} telah berhasil ditandai sebagai terpakai.',
        title: 'Voucher Berhasil Digunakan',
      );
    } else if (_controller.errorMessage.isNotEmpty) {
      showAppSnackBar(
        context,
        _controller.errorMessage,
        title: 'Gagal',
        backgroundColor: AppColors.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          automaticallyImplyLeading: widget.showBackButton,
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
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => TabBar(
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
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.ink),
                );
              }

              final active = _controller.activeVouchers;
              final history = _controller.historyVouchers;

              return TabBarView(
                children: [
                  _buildVoucherList(context, active, isActiveTab: true),
                  _buildVoucherList(context, history, isActiveTab: false),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherList(
    BuildContext context,
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
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RewardCatalogView()),
                  ),
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
            return _buildOverviewBanner(context, vouchers.length, isActiveTab);
          }
          final v = vouchers[index - 1];
          return _buildVoucherCard(v, isActiveTab);
        },
      ),
    );
  }

  Widget _buildOverviewBanner(BuildContext context, int count, bool isActiveTab) {
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RewardCatalogView()),
              ),
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
                      showAppSnackBar(
                        context,
                        'Kode voucher ${voucher.voucherCode} telah disalin.',
                        title: 'Kode Disalin',
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
                  onPressed: () => _showUseVoucherDialog(voucher),
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
                    onTap: () {
                      BookingController().initWizard();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BookingWizardView()),
                      );
                    },
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
