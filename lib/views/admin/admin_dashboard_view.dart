import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/branch_controller.dart';

class AdminDashboardView extends StatelessWidget {
  AdminDashboardView({super.key});

  final AuthController _authController = Get.find<AuthController>();
  final BranchController _branchController = Get.put(BranchController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('PANEL KASIR & ADMIN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.inkSoft),
            tooltip: 'Keluar',
            onPressed: () => _authController.logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Profil Admin
              Obx(() {
                final profile = _authController.currentProfile;
                final name = profile?.name ?? 'Admin Ter The Cut';

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SISTEM MANAJEMEN',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: AppColors.paper.withValues(alpha: 0.6),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              'ADMINISTRATOR',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: AppColors.paper,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.paper,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Akses Penuh: 11 Cabang Barbershop',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.paper.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Sprint Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STATUS SPRINT 1', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 6),
                    Text(
                      'Fondasi Autentikasi & Master Data Siap',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fitur operasional kasir (Jadwal booking harian, aksi Datang & Selesai otomatis) akan diintegrasikan pada Sprint 3.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Ringkasan 11 Cabang
              Text(
                'MONITORING CABANG AKTIF (11)',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 12),

              Obx(() {
                if (_branchController.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.ink));
                }

                return Column(
                  children: _branchController.branches.map((b) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          b.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          b.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkSoft),
                        ),
                        trailing: Text(
                          '2 Kapster',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
