import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/loyalty_controller.dart';
import '../../models/reward.dart';

class RewardCatalogView extends StatelessWidget {
  final bool showBackButton;
  RewardCatalogView({super.key, this.showBackButton = true});

  final LoyaltyController _loyaltyController = Get.isRegistered<LoyaltyController>()
      ? Get.find<LoyaltyController>()
      : Get.put(LoyaltyController());

  final AuthController _authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loyaltyController.loadLoyaltyData();
    });

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
        title: Text(
          'KATALOG REWARD',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Get.toNamed('/my-vouchers'),
            icon: const Icon(Icons.wallet, size: 18, color: AppColors.gold),
            label: Text(
              'VOUCHER',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loyaltyController.loadLoyaltyData(),
          color: AppColors.ink,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Saldo Poin Pelanggan Saat Ini
                Obx(() {
                  final profile = _authController.currentProfile;
                  final points = profile?.pointsBalance ?? 0;
                  final tier = profile?.tier ?? 'Bronze';

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SALDO POIN ANDA',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: AppColors.paper.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$points Pts',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.paper,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Status Member: $tier',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton(
                          onPressed: () => Get.toNamed('/point-ledger'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.paper,
                            side: BorderSide(color: AppColors.paper.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('MUTASI POIN', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),

                Text(
                  'PILIHAN REWARD EKSKLUSIF',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tukarkan poin loyalitas Anda dengan potongan harga atau perawatan rambut gratis.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 16),

                // Daftar Reward
                Obx(() {
                  if (_loyaltyController.isLoading.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: AppColors.ink),
                      ),
                    );
                  }

                  final rewards = _loyaltyController.rewards;
                  final currentPoints = _authController.currentProfile?.pointsBalance ?? 0;

                  return Column(
                    children: rewards.map((reward) {
                      return _buildRewardCard(
                        reward: reward,
                        userPoints: currentPoints,
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard({
    required Reward reward,
    required int userPoints,
  }) {
    final canRedeem = userPoints >= reward.pointsCost;
    final progress = (userPoints / reward.pointsCost).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      if (reward.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          reward.description!,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${reward.pointsCost} Poin',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),

            if (reward.terms != null) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 13, color: AppColors.inkSoft),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      reward.terms!,
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkSoft),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Progress Bar Poin
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      canRedeem ? 'Poin Anda Cukup' : 'Butuh ${reward.pointsCost - userPoints} poin lagi',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: canRedeem ? AppColors.success : AppColors.inkSoft,
                      ),
                    ),
                    Text(
                      '$userPoints / ${reward.pointsCost}',
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkSoft),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.hairline,
                  color: canRedeem ? AppColors.success : AppColors.gold,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tombol Tukar Reward (US-12)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canRedeem ? () => _loyaltyController.redeemReward(reward) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canRedeem ? AppColors.ink : AppColors.hairline,
                  foregroundColor: canRedeem ? AppColors.paper : AppColors.inkSoft,
                ),
                child: Text(
                  canRedeem ? 'TUKAR REWARD SEKARANG' : 'POIN BELUM MENCUKUPI',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

