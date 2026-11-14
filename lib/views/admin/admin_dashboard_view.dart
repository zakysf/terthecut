import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../config/date_format_helper.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admin_controller.dart';
import '../../models/booking.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adminController.loadSchedule();
    });

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(
          'PANEL KASIR & JADWAL',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.inkSoft),
            tooltip: 'Segarkan Jadwal',
            onPressed: () => _adminController.loadSchedule(),
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
        child: RefreshIndicator(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SISTEM KASIR & OPERASIONAL',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.paper.withValues(alpha: 0.6),
                  ),
                ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Kode & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_outlined,
                      size: 16,
                      color: AppColors.inkSoft,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      booking.code,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: statusColor, width: 0.8),
                  ),
                  child: Text(
                    booking.statusLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.hairline),

            // Nama Pelanggan & Nomor Telepon
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.ink),
                const SizedBox(width: 8),
                Text(
                  booking.customerName ?? 'Pelanggan Ter The Cut',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (booking.customerPhone != null &&
                    booking.customerPhone!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${booking.customerPhone})',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),

            // Rincian Layanan & Kapster
            Text(
              '${booking.serviceName} (${booking.durationHours} Jam)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Kapster: ${booking.barberName} • ${booking.branchName}',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 2),
            Text(
              'Jadwal: ${booking.formattedTimeRange}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),

            const SizedBox(height: 12),
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
            const SizedBox(height: 14),

            // Tombol Aksi Kasir: cukup menandai selesai pengerjaan (US-19)
            if (booking.status == 'confirmed' ||
                booking.status == 'arrived') ...[
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
                  ),
                  onPressed: () => _adminController.completeBooking(booking),
                ),
              ),
            ] else if (booking.status == 'completed') ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Layanan selesai. Transaksi dibukukan & +${booking.servicePoints} poin loyalitas berhasil dikreditkan ke member.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
