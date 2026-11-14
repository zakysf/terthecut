import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../config/date_format_helper.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/branch_controller.dart';
import '../../controllers/service_controller.dart';
import '../../controllers/hairstyle_controller.dart';

class BookingWizardView extends StatelessWidget {
  BookingWizardView({super.key});

  final BookingController _bookingController =
      Get.isRegistered<BookingController>()
      ? Get.find<BookingController>()
      : Get.put(BookingController());

  final BranchController _branchController =
      Get.isRegistered<BranchController>()
      ? Get.find<BranchController>()
      : Get.put(BranchController());

  final ServiceController _serviceController =
      Get.isRegistered<ServiceController>()
      ? Get.find<ServiceController>()
      : Get.put(ServiceController());

  final HairstyleController _hairstyleController =
      Get.isRegistered<HairstyleController>()
      ? Get.find<HairstyleController>()
      : Get.put(HairstyleController());

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Obx(() {
          final titles = [
            'PILIH CABANG',
            'PILIH KAPSTER',
            'PILIH LAYANAN',
            'INSPIRASI GAYA',
            'JADWAL & JAM',
            'KONFIRMASI',
          ];
          final step = _bookingController.currentStep.value;
          return Text(
            titles[step],
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          );
        }),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_bookingController.currentStep.value > 0) {
              _bookingController.previousStep();
            } else {
              Get.back();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper Indicator Garis Minimalis
            _buildStepIndicator(),

            // Konten Step Dinamis
            Expanded(
              child: Obx(() {
                switch (_bookingController.currentStep.value) {
                  case 0:
                    return _buildStepBranch();
                  case 1:
                    return _buildStepBarber();
                  case 2:
                    return _buildStepService();
                  case 3:
                    return _buildStepHairstyle();
                  case 4:
                    return _buildStepDateTime();
                  case 5:
                    return _buildStepSummary();
                  default:
                    return _buildStepBranch();
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Indikator Tahapan Wizard 6 Langkah
  Widget _buildStepIndicator() {
    return Obx(() {
      final current = _bookingController.currentStep.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: AppColors.surface,
        child: Column(
          children: [
            Row(
              children: List.generate(6, (index) {
                final isActive = index <= current;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: index < 5 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.accent : AppColors.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Langkah ${current + 1} dari 6',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
                Text(
                  _getStepShortName(current),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  String _getStepShortName(int step) {
    switch (step) {
      case 0:
        return 'Cabang';
      case 1:
        return 'Kapster';
      case 2:
        return 'Layanan';
      case 3:
        return 'Gaya Rambut';
      case 4:
        return 'Jadwal Jam';
      case 5:
        return 'Konfirmasi';
      default:
        return '';
    }
  }

  // ==========================================================================
  // STEP 0: PILIH CABANG (11 Cabang Barbershop)
  // ==========================================================================
  Widget _buildStepBranch() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tentukan Cabang Terdekat',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tersedia 11 cabang resmi Ter The Cut dengan jam operasional 10:00 - 22:00 WIB.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari nama cabang atau jalan...',
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.inkSoft,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onChanged: (val) => _branchController.searchBranches(val),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (_branchController.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.ink),
              );
            }

            final branches = _branchController.branches;
            if (branches.isEmpty) {
              return const Center(child: Text('Cabang tidak ditemukan.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: branches.length,
              itemBuilder: (context, index) {
                final b = branches[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _bookingController.selectBranch(b),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  b.name,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: b.isOpenNow
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : AppColors.danger.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: b.isOpenNow
                                        ? AppColors.success
                                        : AppColors.danger,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  b.statusText,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: b.isOpenNow
                                        ? AppColors.success
                                        : AppColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  b.address,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                b.formattedOperatingHours,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const Text(
                                'PILIH CABANG ->',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // ==========================================================================
  // STEP 1: PILIH KAPSTER (US-07: 2 Kapster per cabang ATAU Bebas/Auto)
  // ==========================================================================
  Widget _buildStepBarber() {
    final branch = _bookingController.selectedBranch.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pilih Kapster Bertugas',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cabang: ${branch?.name ?? "-"}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 16),

          // Pilihan 1: OPSI BEBAS / AUTO-ASSIGN (US-07)
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            child: InkWell(
              onTap: () => _bookingController.selectBarber(null, auto: true),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shuffle,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Bebas / Auto-Assign',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'REKOMENDASI',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.paper,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sistem akan otomatis memilihkan kapster terbaik yang kosong di jam yang Anda inginkan.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.inkSoft,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Divider dengan teks
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.hairline)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ATAU PILIH KAPSTER SPESIFIK',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.hairline)),
            ],
          ),
          const SizedBox(height: 16),

          // Daftar 2 Kapster Cabang Ini
          Obx(() {
            if (_bookingController.isLoadingBarbers.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.ink),
              );
            }

            final barbers = _bookingController.branchBarbers;
            if (barbers.isEmpty) {
              return const Center(
                child: Text('Data kapster cabang sedang dimuat...'),
              );
            }

            return Column(
              children: barbers.map((barber) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _bookingController.selectBarber(barber),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.paper,
                            child: const Icon(
                              Icons.person_outline,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  barber.name,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Kapster Profesional #${barber.sortOrder}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.inkSoft,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================================================
  // STEP 2: PILIH LAYANAN (Durasi bulat 1, 2, atau 3 Jam)
  // ==========================================================================
  Widget _buildStepService() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Layanan Perawatan',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Seluruh layanan Ter The Cut menggunakan durasi bulat per jam (1, 2, atau 3 jam).',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 12),

              // Filter Kategori Pills
              Obx(() {
                final categories = _serviceController.categories;
                final selectedId = _serviceController.selectedCategoryId;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCatPill(
                        'all',
                        'Semua Layanan',
                        selectedId == 'all',
                      ),
                      ...categories.map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildCatPill(
                            c.id,
                            c.name,
                            selectedId == c.id,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (_serviceController.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.ink),
              );
            }

            final services = _serviceController.services;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final svc = services[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _bookingController.selectService(svc),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  svc.name,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                _currencyFormat.format(svc.price),
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                          if (svc.description != null &&
                              svc.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              svc.description!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // Badge Durasi Jam Bulat
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.ink,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.timer_outlined,
                                          size: 12,
                                          color: AppColors.paper,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${svc.durationHours} JAM',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.paper,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Badge Poin
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '+${svc.points} POIN',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'PILIH ->',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCatPill(String id, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _serviceController.filterByCategory(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.paper : AppColors.ink,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // STEP 3: PILIH INSPIRASI GAYA RAMBUT (Opsional)
  // ==========================================================================
  Widget _buildStepHairstyle() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inspirasi Gaya Rambut',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Opsional: Tunjukkan referensi kepada kapster',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _bookingController.skipHairstyle(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text('LEWATI ->', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (_hairstyleController.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.ink),
              );
            }

            final styles = _hairstyleController.hairstyles;
            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: styles.length,
              itemBuilder: (context, index) {
                final hs = styles[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _bookingController.selectHairstyle(hs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child:
                              (hs.photoUrl != null && hs.photoUrl!.isNotEmpty)
                              ? Image.network(
                                  hs.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: AppColors.hairline,
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: AppColors.inkSoft,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: AppColors.hairline,
                                  child: const Icon(
                                    Icons.face,
                                    size: 40,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hs.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pilih Model Ini',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // ==========================================================================
  // STEP 4: PILIH TANGGAL (H+0 s/d H+4) & GRID SLOT JAM BULAT (US-08)
  // ==========================================================================
  Widget _buildStepDateTime() {
    final service = _bookingController.selectedService.value;
    final duration = service?.durationHours ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Tanggal & Jam Reservasi',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Durasi layanan ini: $duration Jam. Slot jam ditampilkan bulat per jam 10:00 - 21:00 WIB.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 14),

              // Strip Tanggal H+0 s/d H+4 (5 Hari)
              Text(
                'PILIH TANGGAL (5 HARI KE DEPAN):',
                style: Theme.of(Get.context!).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _bookingController.availableDates.length,
                  itemBuilder: (context, index) {
                    final date = _bookingController.availableDates[index];
                    return Obx(() {
                      final selectedDate =
                          _bookingController.selectedDate.value;
                      final isSelected =
                          date.year == selectedDate.year &&
                          date.month == selectedDate.month &&
                          date.day == selectedDate.day;

                      final dayName = IndonesianDateHelper.dayShort(date);
                      final dayNum = '${date.day}';
                      final monthName = IndonesianDateHelper.monthShort(date);

                      return GestureDetector(
                        onTap: () => _bookingController.selectDate(date),
                        child: Container(
                          width: 65,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.ink
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.ink
                                  : AppColors.hairline,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.gold
                                      : AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dayNum,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.paper
                                      : AppColors.ink,
                                ),
                              ),
                              Text(
                                monthName,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: isSelected
                                      ? AppColors.paper.withValues(alpha: 0.7)
                                      : AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        const Divider(color: AppColors.hairline),

        // Grid Slot Jam Bulat 10:00 - 21:00
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PILIH JAM MULAI:',
                      style: Theme.of(Get.context!).textTheme.labelSmall,
                    ),
                    Row(
                      children: [
                        _buildLegend(AppColors.surface, 'Tersedia'),
                        const SizedBox(width: 8),
                        _buildLegend(AppColors.hairline, 'Penuh/Lewat'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Obx(() {
                    if (_bookingController.isLoadingSlots.value) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.ink),
                      );
                    }

                    final slots = _bookingController.availableSlots;
                    if (slots.isEmpty) {
                      return Center(
                        child: Text(
                          _bookingController.errorMessage.value.isNotEmpty
                              ? _bookingController.errorMessage.value
                              : 'Tidak ada slot jam tersedia.',
                          style: GoogleFonts.inter(color: AppColors.inkSoft),
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.1,
                          ),
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        return Obx(() {
                          final selectedSlot =
                              _bookingController.selectedSlot.value;
                          final isSelected = selectedSlot?.hour == slot.hour;

                          Color bgColor;
                          Color textColor;
                          Border border;

                          if (isSelected) {
                            bgColor = AppColors.ink;
                            textColor = AppColors.paper;
                            border = Border.all(color: AppColors.ink, width: 2);
                          } else if (!slot.isAvailable) {
                            bgColor = AppColors.paper;
                            textColor = AppColors.inkSoft.withValues(
                              alpha: 0.4,
                            );
                            border = Border.all(
                              color: AppColors.hairline.withValues(alpha: 0.5),
                            );
                          } else {
                            bgColor = AppColors.surface;
                            textColor = AppColors.ink;
                            border = Border.all(color: AppColors.hairline);
                          }

                          return InkWell(
                            onTap: slot.isAvailable
                                ? () => _bookingController.selectSlot(slot)
                                : null,
                            child: Container(
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(4),
                                border: border,
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    slot.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: textColor,
                                      decoration:
                                          (!slot.isAvailable && slot.isPast)
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                  if (!slot.isAvailable)
                                    Text(
                                      slot.isPast
                                          ? 'Lewat'
                                          : (slot.reason ?? 'Penuh'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: textColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),

        // Bottom CTA Lanjut ke Ringkasan
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.hairline)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'WAKTU TERPILIH',
                    style: Theme.of(Get.context!).textTheme.labelSmall,
                  ),
                  Obx(() {
                    final slot = _bookingController.selectedSlot.value;
                    return Text(
                      slot != null
                          ? '${slot.label} - ${(slot.hour + duration).toString().padLeft(2, '0')}:00 WIB'
                          : 'Belum memilih jam',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: slot != null
                            ? AppColors.accent
                            : AppColors.inkSoft,
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _bookingController.proceedToSummary(),
                  child: const Text('LANJUT KE RINGKASAN ->'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkSoft),
        ),
      ],
    );
  }

  // ==========================================================================
  // STEP 5: RINGKASAN & KONFIRMASI (US-09 Anti-Double Booking Booking RPC)
  // ==========================================================================
  Widget _buildStepSummary() {
    final branch = _bookingController.selectedBranch.value;
    final barber = _bookingController.selectedBarber.value;
    final isAuto = _bookingController.isAutoAssign.value;
    final service = _bookingController.selectedService.value;
    final hairstyle = _bookingController.selectedHairstyle.value;
    final date = _bookingController.selectedDate.value;
    final slot = _bookingController.selectedSlot.value;
    final duration = service?.durationHours ?? 1;

    final startHour = slot?.hour ?? 10;
    final endHour = startHour + duration;
    final timeRangeStr =
        '${startHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00 WIB';
    final dateStr = IndonesianDateHelper.formatFull(date);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Konfirmasi Reservasi',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Periksa kembali rincian jadwal dan layanan Anda sebelum menyelesaikan reservasi.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 20),

          // Tiket Editorial Mewah
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.hairline),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Tiket
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'TER THE CUT BARBERSHOP',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.paper,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: AppColors.gold, width: 0.5),
                        ),
                        child: Text(
                          'RESERVASI',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Isi Tiket
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTicketRow('CABANG', branch?.name ?? '-'),
                      const SizedBox(height: 4),
                      Text(
                        branch?.address ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const Divider(height: 24, color: AppColors.hairline),
                      _buildTicketRow(
                        'KAPSTER',
                        isAuto
                            ? 'Bebas / Auto-Assign (Dipilihkan Sistem)'
                            : (barber?.name ?? '-'),
                      ),
                      const SizedBox(height: 12),
                      _buildTicketRow('LAYANAN', service?.name ?? '-'),
                      const SizedBox(height: 12),
                      _buildTicketRow('DURASI', '$duration Jam Bulat'),
                      if (hairstyle != null) ...[
                        const SizedBox(height: 12),
                        _buildTicketRow('INSPIRASI GAYA', hairstyle.name),
                      ],
                      const Divider(height: 24, color: AppColors.hairline),
                      _buildTicketRow('TANGGAL', dateStr),
                      const SizedBox(height: 12),
                      _buildTicketRow('JAM RESERVASI', timeRangeStr),
                      const Divider(height: 24, color: AppColors.hairline),

                      // Bagian Voucher Diskon
                      Obx(() {
                        final applied = _bookingController.appliedVoucher.value;
                        final usable = _bookingController.usableVouchers;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.confirmation_num_outlined,
                                      size: 14,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'VOUCHER DISKON',
                                      style: Theme.of(Get.context!)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ],
                                ),
                                if (applied != null)
                                  GestureDetector(
                                    onTap: () => _bookingController.removeVoucher(),
                                    child: Text(
                                      'Hapus',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (applied != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            applied.rewardName,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            applied.voucherCode,
                                            style: const TextStyle(
                                              fontFamily: 'Playfair Display',
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                              color: AppColors.inkSoft,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '-${_currencyFormat.format(_bookingController.discountAmount)}',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (usable.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () => _showVoucherPicker(Get.context!),
                                icon: const Icon(
                                  Icons.local_offer_outlined,
                                  size: 14,
                                  color: AppColors.ink,
                                ),
                                label: Text(
                                  'Pilih Voucher (${usable.length} Tersedia)',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  side: const BorderSide(color: AppColors.hairline),
                                ),
                              )
                            else
                              Text(
                                'Tidak ada voucher aktif untuk akun ini.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                          ],
                        );
                      }),

                      const Divider(height: 24, color: AppColors.hairline),
                      Obx(() {
                        final discount = _bookingController.discountAmount;
                        final finalTotal = _bookingController.finalPrice;
                        final origPrice = service?.price ?? 0;

                        return Column(
                          children: [
                            if (discount > 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Harga Normal',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                  Text(
                                    _currencyFormat.format(origPrice),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Diskon Voucher',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                  Text(
                                    '-${_currencyFormat.format(discount)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL BIAYA',
                                      style: Theme.of(Get.context!)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _currencyFormat.format(finalTotal),
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.stars,
                                        color: AppColors.gold,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+${service?.points ?? 10} POIN',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Konfirmasi Final
          Obx(() {
            final isSubmitting = _bookingController.isSubmitting.value;
            return ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () => _bookingController.confirmBooking(),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.paper,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('KONFIRMASI RESERVASI SEKARANG'),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTicketRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            style: Theme.of(Get.context!).textTheme.labelSmall,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  void _showVoucherPicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PILIH VOUCHER REWARD',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Obx(() {
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: _bookingController.usableVouchers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final v = _bookingController.usableVouchers[index];
                    final isSelected =
                        _bookingController.appliedVoucher.value?.voucherCode ==
                            v.voucherCode;
                    return InkWell(
                      onTap: () {
                        _bookingController.applyVoucher(v);
                        Get.back();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.gold
                                : AppColors.hairline,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.card_giftcard,
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.inkSoft,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.rewardName,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Kode: ${v.voucherCode} • Berlaku s.d. ${v.formattedExpiry}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.gold,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 14),
            Obx(() {
              if (_bookingController.appliedVoucher.value != null) {
                return OutlinedButton(
                  onPressed: () {
                    _bookingController.removeVoucher();
                    Get.back();
                  },
                  child: const Text('BATALKAN PENGGUNAAN VOUCHER'),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
