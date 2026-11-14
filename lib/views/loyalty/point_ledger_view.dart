import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/loyalty_controller.dart';
import '../../models/point_ledger.dart';

class PointLedgerView extends StatelessWidget {
  final bool showBackButton;
  PointLedgerView({super.key, this.showBackButton = true});

  final LoyaltyController _controller = Get.isRegistered<LoyaltyController>()
      ? Get.find<LoyaltyController>()
      : Get.put(LoyaltyController());

  final AuthController _authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadLoyaltyData();
    });

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
        title: Text(
          'MUTASI & RIWAYAT POIN',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _controller.loadLoyaltyData(),
          color: AppColors.ink,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kartu Ringkasan Poin & Tier (US-02 & US-11)
                Obx(() {
                  final profile = _authController.currentProfile;
                  final points = profile?.pointsBalance ?? 0;
                  final lifetime = profile?.lifetimePoints ?? 0;
                  final tier = profile?.tier ?? 'Bronze';

                  // Tier thresholds
                  int nextTierPoints = 100;
                  String nextTierName = 'Silver';
                  double progress = (points / 100).clamp(0.0, 1.0);

                  if (tier == 'Silver') {
                    nextTierPoints = 300;
                    nextTierName = 'Gold';
                    progress = ((points - 100) / 200).clamp(0.0, 1.0);
                  } else if (tier == 'Gold') {
                    nextTierPoints = 300;
                    nextTierName = 'Maksimal';
                    progress = 1.0;
                  }

                  return Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'STATUS LOYALITAS',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                color: AppColors.paper.withValues(alpha: 0.7),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                tier.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: AppColors.paper,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$points',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.paper,
                                  ),
                                ),
                                Text(
                                  'SALDO POIN AKTIF',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                    color: AppColors.paper.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$lifetime Pts',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.gold,
                                  ),
                                ),
                                Text(
                                  'TOTAL AKUMULASI',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.0,
                                    color: AppColors.paper.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.hairline, height: 1),
                        const SizedBox(height: 14),

                        // Progres Tier
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tier == 'Gold'
                                  ? 'Tingkat Tier Tertinggi'
                                  : 'Menuju $nextTierName ($points/$nextTierPoints Pts)',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.paper.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.paper.withValues(alpha: 0.2),
                          color: AppColors.gold,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RIWAYAT MUTASI POIN',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    TextButton(
                      onPressed: () => Get.toNamed('/rewards'),
                      child: const Text('TUKAR REWARD', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Daftar Mutasi Poin
                Obx(() {
                  if (_controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.ink));
                  }

                  final ledger = _controller.pointLedger;
                  if (ledger.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.inkSoft.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'Belum Ada Mutasi Poin',
                            style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Setiap kali kunjungan potong rambut Anda diselesaikan oleh kasir, poin otomatis bertambah di sini.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: ledger.map((entry) => _buildLedgerTile(entry)).toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLedgerTile(PointLedgerEntry entry) {
    final isPos = entry.isPositive;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPos
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPos ? Icons.add : Icons.remove,
                color: isPos ? AppColors.success : AppColors.danger,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.note ?? entry.reasonLabel,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.reasonLabel} • ${entry.formattedDate}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            Text(
              entry.formattedDelta,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isPos ? AppColors.success : AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

