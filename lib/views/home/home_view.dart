import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/branch_controller.dart';
import '../../controllers/booking_controller.dart';

class HomeView extends StatelessWidget {
  HomeView({super.key});

  final AuthController _authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);
  final BranchController _branchController = Get.put(BranchController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(
          'TER THE CUT',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: AppColors.ink,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note_outlined, size: 22, color: AppColors.ink),
            tooltip: 'Booking Saya',
            onPressed: () {
              final bc = Get.isRegistered<BookingController>()
                  ? Get.find<BookingController>()
                  : Get.put(BookingController());
              bc.loadMyBookings();
              Get.toNamed('/my-bookings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: AppColors.inkSoft),
            tooltip: 'Keluar',
            onPressed: () {
              Get.defaultDialog(
                title: 'Konfirmasi Keluar',
                middleText: 'Apakah Anda yakin ingin keluar dari akun?',
                textConfirm: 'Ya, Keluar',
                textCancel: 'Batal',
                confirmTextColor: AppColors.paper,
                buttonColor: AppColors.ink,
                onConfirm: () {
                  Get.back();
                  _authController.logout();
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sapaan Editorial
              Obx(() {
                final profile = _authController.currentProfile;
                final name = profile?.name ?? 'Pelanggan';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat datang,',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    Text(
                      name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 20),

              // Digital Membership Card (Editorial Style)
              Obx(() {
                final profile = _authController.currentProfile;
                final tier = profile?.tier ?? 'Bronze';
                final points = profile?.pointsBalance ?? 0;
                final lifetime = profile?.lifetimePoints ?? 0;
                final name = profile?.name ?? 'Ter The Cut Member';

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
                            'MEMBERSHIP CARD',
                            style: GoogleFonts.inter(
                              fontSize: 11,
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
                      const SizedBox(height: 24),
                      Text(
                        '$points',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: AppColors.paper,
                        ),
                      ),
                      Text(
                        'SALDO POIN LOYALITAS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: AppColors.paper.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 2,
                        color: AppColors.paper.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: AppColors.paper,
                            ),
                          ),
                          Text(
                            'Akumulasi: $lifetime Pts',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.paper.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Tombol Utama Reservasi Jadwal (Sprint 2)
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_month_outlined, size: 20),
                label: const Text('RESERVASI JADWAL SEKARANG'),
                onPressed: () {
                  final bc = Get.isRegistered<BookingController>()
                      ? Get.find<BookingController>()
                      : Get.put(BookingController());
                  bc.initWizard();
                  Get.toNamed('/booking-wizard');
                },
              ),
              const SizedBox(height: 28),

              // Menu Pintasan Cepat
              Text(
                'LAYANAN UTAMA',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildQuickAction(
                    icon: Icons.store_outlined,
                    label: '11 Cabang',
                    onTap: () => Get.toNamed('/branches'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    icon: Icons.content_cut_outlined,
                    label: 'Layanan',
                    onTap: () => Get.toNamed('/services'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    icon: Icons.face_outlined,
                    label: 'Inspirasi',
                    onTap: () => Get.toNamed('/hairstyles'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    icon: Icons.event_note_outlined,
                    label: 'Jadwal Saya',
                    onTap: () {
                      final bc = Get.isRegistered<BookingController>()
                          ? Get.find<BookingController>()
                          : Get.put(BookingController());
                      bc.loadMyBookings();
                      Get.toNamed('/my-bookings');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Bagian Cabang Populer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LOKASI CABANG',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed('/branches'),
                    child: Text(
                      'Lihat Semua (11)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (_branchController.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: AppColors.ink),
                    ),
                  );
                }

                final previewBranches = _branchController.branches.take(3).toList();
                return Column(
                  children: previewBranches.map((branch) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                branch.name,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              branch.statusText,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: branch.isOpenNow ? AppColors.success : AppColors.danger,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            branch.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.inkSoft),
                        onTap: () => Get.toNamed('/branch-detail', arguments: branch),
                      ),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 24),

              // Editorial Promo Teaser Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, color: AppColors.accent, size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tukar Reward dengan Poinmu',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dapatkan potongan hingga gratis potong rambut untuk setiap akumulasi kunjungan.',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: AppColors.ink),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
