import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../config/date_format_helper.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/feedback_controller.dart';
import '../../controllers/promotion_controller.dart';
import '../../models/booking.dart';
import '../../models/profile.dart';
import '../../models/promotion.dart';

class AdminDashboardView extends StatelessWidget {
  AdminDashboardView({super.key});

  final AuthController _authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController(), permanent: true);

  final AdminController _adminController = Get.put(AdminController());

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final FeedbackController feedbackController = Get.put(FeedbackController());
    final PromotionController promotionController = Get.put(PromotionController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adminController.loadSchedule();
      feedbackController.loadFeedbacks();
      promotionController.loadPromotions();
    });

    final RxInt currentTabIndex = 0.obs;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(
          'PANEL KASIR & ADMIN',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.playfairDisplay(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.inkSoft),
            tooltip: 'Segarkan Data',
            onPressed: () {
              _adminController.loadSchedule();
              feedbackController.loadFeedbacks();
              promotionController.loadPromotions();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.inkSoft),
            tooltip: 'Keluar',
            onPressed: () {
              Get.defaultDialog(
                title: 'Konfirmasi Keluar',
                middleText: 'Apakah Anda ingin keluar dari panel admin kasir?',
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
        child: Obx(() {
          switch (currentTabIndex.value) {
            case 0:
              return _buildScheduleTab(context);
            case 1:
              return _buildCustomerSearchTab();
            case 2:
              return _buildFeedbackTab(feedbackController);
            case 3:
              return _buildPromotionsTab(context, promotionController);
            default:
              return _buildScheduleTab(context);
          }
        }),
      ),
      bottomNavigationBar: Obx(
        () => Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.hairline, width: 0.8),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: currentTabIndex.value,
            onTap: (index) => currentTabIndex.value = index,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.accent,
            unselectedItemColor: AppColors.inkSoft,
            selectedLabelStyle: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Jadwal',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_search_outlined),
                activeIcon: Icon(Icons.person_search),
                label: 'Member',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.rate_review_outlined),
                activeIcon: Icon(Icons.rate_review),
                label: 'Masukan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_offer_outlined),
                activeIcon: Icon(Icons.local_offer),
                label: 'Promo',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _adminController.loadSchedule(),
      color: AppColors.ink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                // Header Profil Admin & Akses Cabang
                _buildAdminHeader(),
                const SizedBox(height: 20),

                // Filter Cabang & Tanggal (US-18)
                _buildFilterSection(),
                const SizedBox(height: 20),

                // Ringkasan Kasir & Operasional Harian
                _buildSummaryMetrics(),
                const SizedBox(height: 24),

                // Status Tabs (Filter Cepat)
                _buildStatusFilterPills(),
                const SizedBox(height: 16),

                // Daftar Antrean Booking & Aksi Kasir (US-18 & US-19)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ANTREAN RESERVASI HARIAN',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Obx(() {
                      return Text(
                        'Total: ${_adminController.filteredBookings.length} Jadwal',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.inkSoft,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),

                Obx(() {
                  if (_adminController.isLoading.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(color: AppColors.ink),
                      ),
                    );
                  }

                  final bookings = _adminController.filteredBookings;
                  if (bookings.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.event_available,
                            size: 40,
                            color: AppColors.inkSoft,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak Ada Booking Pada Kriteria Ini',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Silakan pilih tanggal lain atau cabang lain untuk memantau jadwal reservasi.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: bookings
                        .map((b) => _buildBookingCashierCard(b))
                        .toList(),
                  );
                }),
              ],
            ),
          ),
        );
  }

  Widget _buildAdminHeader() {
    return Obx(() {
      final profile = _authController.currentProfile;
      final name = profile?.name ?? 'Admin Kasir Ter The Cut';

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'SISTEM KASIR & OPERASIONAL',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.paper.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'KASIR AKTIF',
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
            const SizedBox(height: 14),
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
              'Otoritas Penuh: Pembukuan Transaksi & Akumulasi Poin Otomatis',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.paper.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FILTER CABANG (11 CABANG)',
            style: Theme.of(Get.context!).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),

          // Dropdown Cabang
          Obx(() {
            final branches = _adminController.branches;
            final selected = _adminController.selectedBranchId.value;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.hairline),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selected,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.ink,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('Semua Cabang (11 Cabang)'),
                    ),
                    ...branches.map((b) {
                      return DropdownMenuItem(
                        value: b.id,
                        child: Text(b.name, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    if (val != null) _adminController.changeBranch(val);
                  },
                ),
              ),
            );
          }),

          const SizedBox(height: 14),
          Text(
            'TANGGAL JADWAL',
            style: Theme.of(Get.context!).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),

          // Tombol Pemilih Tanggal Cepat
          Obx(() {
            final date = _adminController.selectedDate.value;
            final now = DateTime.now();
            final isToday =
                date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            final dateLabel = IndonesianDateHelper.formatFull(date);

            return Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$dateLabel ${isToday ? "(Hari Ini)" : ""}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: AppColors.ink),
                  icon: const Icon(
                    Icons.date_range,
                    color: AppColors.paper,
                    size: 18,
                  ),
                  tooltip: 'Pilih Tanggal',
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: Get.context!,
                      initialDate: _adminController.selectedDate.value,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 7),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 14)),
                    );
                    if (picked != null) {
                      _adminController.changeDate(picked);
                    }
                  },
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics() {
    return Obx(() {
      final total = _adminController.totalToday;
      final pending = _adminController.pendingCount;
      final completed = _adminController.completedCount;
      final revenue = _adminController.totalRevenue;
      final points = _adminController.totalPointsAwarded;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatItem('TOTAL RESERVASI', '$total', AppColors.ink),
                _buildStatItem(
                  'MENUNGGU / AKTIF',
                  '$pending',
                  AppColors.accent,
                ),
                _buildStatItem(
                  'SELESAI (KASIR)',
                  '$completed',
                  AppColors.success,
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.hairline),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OMSET TERBUKU (KASIR)',
                      style: Theme.of(Get.context!).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currencyFormat.format(revenue),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'POIN DIBAGIKAN',
                      style: Theme.of(Get.context!).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+$points Pts',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterPills() {
    final filters = [
      {'id': 'all', 'label': 'Semua'},
      {'id': 'confirmed', 'label': 'Menunggu / Aktif'},
      {'id': 'completed', 'label': 'Selesai'},
    ];

    return Obx(() {
      final active = _adminController.statusFilter.value;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = active == f['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _adminController.setStatusFilter(f['id']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.ink : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.ink : AppColors.hairline,
                    ),
                  ),
                  child: Text(
                    f['label']!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? AppColors.paper : AppColors.ink,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildBookingCashierCard(Booking booking) {
    Color statusColor;
    Color statusBgColor;

    switch (booking.status) {
      case 'confirmed':
        statusColor = AppColors.accent;
        statusBgColor = AppColors.accent.withValues(alpha: 0.1);
        break;
      case 'arrived':
        statusColor = AppColors.gold;
        statusBgColor = AppColors.gold.withValues(alpha: 0.1);
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusBgColor = AppColors.success.withValues(alpha: 0.1);
        break;
      case 'cancelled':
        statusColor = AppColors.danger;
        statusBgColor = AppColors.danger.withValues(alpha: 0.1);
        break;
      default:
        statusColor = AppColors.inkSoft;
        statusBgColor = AppColors.hairline;
    }

    final String customerName = booking.customerName?.trim().isNotEmpty == true
        ? booking.customerName!
        : 'Pelanggan Walk-In';
    final String initial = customerName.isNotEmpty ? customerName[0].toUpperCase() : 'P';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.hairline.withValues(alpha: 0.9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: Kode Booking & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 12, color: AppColors.inkSoft),
                      const SizedBox(width: 4),
                      Text(
                        '#${booking.code}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor, width: 0.8),
                  ),
                  child: Text(
                    booking.statusLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Baris 2: FOCUS UTAMA - "Ini Antrean Siapa Dulu"
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.ink.withValues(alpha: 0.08),
                  child: Text(
                    initial,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      if (booking.customerPhone != null &&
                          booking.customerPhone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 12, color: AppColors.inkSoft),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                booking.customerPhone!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Baris 3: Box Rincian Layanan, Kapster, dan Jam (Spacious, Zero-Crowding)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.hairline.withValues(alpha: 0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'Jadwal: ',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkSoft),
                      ),
                      Flexible(
                        child: Text(
                          booking.formattedTimeRange,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.content_cut_outlined, size: 14, color: AppColors.ink),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${booking.serviceName} (${booking.durationHours} Jam)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.inkSoft),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Kapster: ${booking.barberName} • ${booking.branchName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Baris 4: Biaya & Perolehan Poin
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currencyFormat.format(booking.servicePrice)} • +${booking.servicePoints} Poin',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),

            // Baris 5: Tombol Aksi Kasir (Hanya jika belum selesai)
            if (booking.status == 'confirmed' ||
                booking.status == 'arrived') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text(
                    'SELESAIKAN (KASIR)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _adminController.completeBooking(booking),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 2: PENCARIAN CEPAT DATA PELANGGAN (US-20, Debounce 300ms)
  // ==========================================================================
  Widget _buildCustomerSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PENCARIAN DATA PELANGGAN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cari profil, saldo poin, dan tingkatan member berdasarkan nama atau nomor telepon (Debounce 300 ms).',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            onChanged: (val) => _adminController.customerSearchQuery.value = val,
            decoration: InputDecoration(
              hintText: 'Ketik nama / nomor telepon pelanggan...',
              prefixIcon: const Icon(Icons.search, color: AppColors.inkSoft),
              suffixIcon: Obx(() {
                if (_adminController.customerSearchQuery.value.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _adminController.customerSearchQuery.value = '',
                  );
                }
                return const SizedBox.shrink();
              }),
            ),
          ),
          const SizedBox(height: 20),

          // Search Results
          Obx(() {
            if (_adminController.isSearching.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppColors.ink),
                ),
              );
            }

            final query = _adminController.customerSearchQuery.value.trim();
            final results = _adminController.searchedCustomers;

            if (query.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.hairline),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.person_search, size: 40, color: AppColors.inkSoft),
                    const SizedBox(height: 12),
                    Text(
                      'Cari Member Ter The Cut',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Masukkan nomor HP (misal: 08123456789) atau nama pelanggan untuk melihat riwayat keanggotaan.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              );
            }

            if (results.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.hairline),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.person_off_outlined, size: 40, color: AppColors.inkSoft),
                    const SizedBox(height: 12),
                    Text(
                      'Pelanggan Tidak Ditemukan',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tidak ada pelanggan dengan kata kunci "$query". Pastikan nomor telepon atau ejaan nama sudah sesuai.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'HASIL PENCARIAN (${results.length} PELANGGAN)',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 10),
                ...results.map((profile) => _buildCustomerCard(profile)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Profile profile) {
    Color tierColor = AppColors.inkSoft;
    switch (profile.tier.toLowerCase()) {
      case 'silver':
        tierColor = const Color(0xFF758A99);
        break;
      case 'gold':
        tierColor = AppColors.gold;
        break;
      case 'platinum':
        tierColor = AppColors.ink;
        break;
      default:
        tierColor = AppColors.accent;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.ink.withValues(alpha: 0.08),
                  child: Text(
                    (profile.name ?? 'P')[0].toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name ?? 'Tanpa Nama',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.phone ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: tierColor, width: 0.8),
                  ),
                  child: Text(
                    profile.tier.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: tierColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.hairline),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SALDO POIN AKTIF',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.pointsBalance} Poin',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL POIN SEUMUR HIDUP',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.lifetimePoints} Pts',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 3: MASUKAN & KRITIK SARAN PELANGGAN (US-15, STRICTLY READ-ONLY)
  // ==========================================================================
  Widget _buildFeedbackTab(FeedbackController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.loadFeedbacks(),
      color: AppColors.ink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MASUKAN & SARAN PELANGGAN',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.inkSoft,
                  ),
                ),
                Obx(() {
                  return Text(
                    '${controller.feedbacks.length} Masukan',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Umpan balik pelanggan bersifat read-only untuk menjaga integritas data evaluasi operasional.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 16),

            Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.ink),
                  ),
                );
              }

              final items = controller.feedbacks;
              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.rate_review_outlined, size: 40, color: AppColors.inkSoft),
                      const SizedBox(height: 12),
                      Text(
                        'Belum Ada Kritik & Saran',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Masukan dari pelanggan yang dikirim melalui aplikasi akan tersaji di layar ini.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: items.map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
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
                                  item.userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  item.category.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 12, color: AppColors.inkSoft),
                              const SizedBox(width: 4),
                              Text(
                                IndonesianDateHelper.formatShort(item.createdAt),
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkSoft),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(4),
                              border: const Border(
                                left: BorderSide(color: AppColors.ink, width: 3),
                              ),
                            ),
                            child: Text(
                              item.message,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 4: MANAJEMEN PROMO & DISKON SEGMEN (US-17)
  // ==========================================================================
  Widget _buildPromotionsTab(BuildContext context, PromotionController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.loadPromotions(),
      color: AppColors.ink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'MANAJEMEN PROMO SEGMEN',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kelola diskon eksklusif berbasis segmen tier pelanggan.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'TAMBAH PROMO BARU',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _showPromoFormModal(context, controller),
              ),
            ),
            const SizedBox(height: 14),

            Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.ink),
                  ),
                );
              }

              final promos = controller.allPromotions;
              if (promos.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.local_offer_outlined, size: 40, color: AppColors.inkSoft),
                      const SizedBox(height: 12),
                      Text(
                        'Belum Ada Promo Aktif',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Klik tombol "+ Tambah Promo" untuk menyusun promo berbasis segmen tier pelanggan.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: promos.map((p) {
                  final isActive = p.isValidNow;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${p.discountPercent}% OFF',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.success.withValues(alpha: 0.15)
                                      : AppColors.inkSoft.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  isActive ? 'AKTIF' : 'NONAKTIF',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? AppColors.success : AppColors.inkSoft,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Tombol Edit (CRUD - Update)
                              InkWell(
                                onTap: () => _showPromoFormModal(context, controller, promo: p),
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.edit_outlined, size: 18, color: AppColors.ink),
                                ),
                              ),
                              // Tombol Delete (CRUD - Delete)
                              InkWell(
                                onTap: () => _confirmDeletePromo(controller, p),
                                borderRadius: BorderRadius.circular(4),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.description,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Segmen: ${p.targetTier.toUpperCase()}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                              Text(
                                '${IndonesianDateHelper.formatDateOnly(p.startDate)} - ${IndonesianDateHelper.formatDateOnly(p.endDate)}',
                                style: GoogleFonts.inter(fontSize: 10, color: AppColors.inkSoft),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePromo(PromotionController controller, Promotion promo) {
    Get.defaultDialog(
      title: 'Hapus Promo',
      middleText: 'Apakah Anda yakin ingin menghapus promo "${promo.title}"?',
      textConfirm: 'Ya, Hapus',
      textCancel: 'Batal',
      confirmTextColor: AppColors.paper,
      buttonColor: AppColors.danger,
      onConfirm: () {
        Get.back();
        controller.deletePromotion(promo.id);
      },
    );
  }

  void _showPromoFormModal(
    BuildContext context,
    PromotionController controller, {
    Promotion? promo,
  }) {
    final isEditing = promo != null;
    final titleCtrl = TextEditingController(text: promo?.title ?? '');
    final descCtrl = TextEditingController(text: promo?.description ?? '');
    final discountCtrl = TextEditingController(
      text: promo?.discountPercent.toString() ?? '15',
    );
    String targetTier = promo?.targetTier.toLowerCase() ?? 'all';
    DateTime startDate = promo?.startDate ?? DateTime.now();
    DateTime endDate = promo?.endDate ?? DateTime.now().add(const Duration(days: 30));
    bool isActive = promo?.isActive ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: SafeArea(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(modalContext).size.height * 0.85,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEditing ? 'Ubah Promo' : 'Tambah Promo Baru',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => Get.back(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Judul Promo',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi Singkat',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: discountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Diskon',
                                  suffixText: '%',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                initialValue: targetTier,
                                isDense: true,
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink),
                                decoration: const InputDecoration(
                                  labelText: 'Target Tier',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text('Semua', style: TextStyle(fontSize: 12)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'silver',
                                    child: Text('Silver', style: TextStyle(fontSize: 12)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'gold',
                                    child: Text('Gold', style: TextStyle(fontSize: 12)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'platinum',
                                    child: Text('Platinum', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => targetTier = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        if (isEditing) ...[
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Status Promo Aktif',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            value: isActive,
                            activeTrackColor: AppColors.accent,
                            onChanged: (val) => setState(() => isActive = val),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            final disc = int.tryParse(discountCtrl.text.trim()) ?? 10;
                            if (isEditing) {
                              final updated = promo.copyWith(
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                discountPercent: disc,
                                targetTier: targetTier,
                                isActive: isActive,
                              );
                              final ok = await controller.updatePromotion(updated);
                              if (ok) Get.back();
                            } else {
                              final ok = await controller.createPromotion(
                                title: titleCtrl.text,
                                description: descCtrl.text,
                                discountPercent: disc,
                                targetTier: targetTier,
                                startDate: startDate,
                                endDate: endDate,
                              );
                              if (ok) Get.back();
                            }
                          },
                          child: Text(
                            isEditing ? 'SIMPAN PERUBAHAN' : 'SIMPAN & PUBLIKASIKAN PROMO',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
