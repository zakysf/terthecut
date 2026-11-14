import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../controllers/booking_controller.dart';
import '../../models/booking.dart';

class MyBookingsView extends StatelessWidget {
  final bool showBackButton;
  MyBookingsView({super.key, this.showBackButton = true});

  final BookingController _controller = Get.isRegistered<BookingController>()
      ? Get.find<BookingController>()
      : Get.put(BookingController());

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadMyBookings();
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          automaticallyImplyLeading: showBackButton,
          title: Text(
            'BOOKING SAYA',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Obx(() {
              final upcomingCount = _controller.upcomingBookings.length;
              final historyCount = _controller.historyBookings.length;
              return TabBar(
                labelColor: AppColors.ink,
                unselectedLabelColor: AppColors.inkSoft,
                indicatorColor: AppColors.accent,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Akan Datang ($upcomingCount)'),
                  Tab(text: 'Riwayat Selesai ($historyCount)'),
                ],
              );
            }),
          ),
        ),
        body: SafeArea(
          child: Obx(() {
            if (_controller.isLoadingBookings.value) {
              return const Center(child: CircularProgressIndicator(color: AppColors.ink));
            }

            final upcoming = _controller.upcomingBookings;
            final history = _controller.historyBookings;

            return TabBarView(
              children: [
                _buildBookingList(upcoming, isUpcoming: true),
                _buildBookingList(history, isUpcoming: false),
              ],
            );
          }),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _controller.initWizard();
            Get.toNamed('/booking-wizard');
          },
          backgroundColor: AppColors.ink,
          icon: const Icon(Icons.add, color: AppColors.paper),
          label: Text(
            'PESAN BARU',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.paper,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, {required bool isUpcoming}) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUpcoming ? Icons.calendar_today_outlined : Icons.history,
                size: 48,
                color: AppColors.inkSoft.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                isUpcoming ? 'Belum Ada Jadwal Aktif' : 'Belum Ada Riwayat Kunjungan',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isUpcoming
                    ? 'Pilih cabang dan kapster favorit Anda untuk melakukan reservasi potong rambut.'
                    : 'Riwayat layanan dan poin yang diperoleh akan tampil di sini setelah kunjungan selesai.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
              ),
              if (isUpcoming && _controller.historyBookings.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Jadwal Anda telah selesai di tab "Riwayat Selesai".',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isUpcoming) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _controller.initWizard();
                    Get.toNamed('/booking-wizard');
                  },
                  child: const Text('RESERVASI SEKARANG'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _controller.loadMyBookings(),
      color: AppColors.ink,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking, isUpcoming);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, bool isUpcoming) {
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
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Get.toNamed('/booking-detail', arguments: booking),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card: Kode Booking & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.inkSoft),
                      const SizedBox(width: 6),
                      Text(
                        booking.code,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

              // Rincian Layanan & Cabang
              Text(
                booking.serviceName,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.store_outlined, size: 14, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.branchName,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppColors.inkSoft),
                  const SizedBox(width: 6),
                  Text(
                    'Kapster: ${booking.barberName}${booking.barberPref == 'auto' ? ' (Auto-Assign)' : ''}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.inkSoft),
                  const SizedBox(width: 6),
                  Text(
                    '${booking.formattedDate} • ${booking.formattedTimeRange}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Bottom Card: Harga, Poin, & Tombol Aksi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currencyFormat.format(booking.servicePrice),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '+${booking.servicePoints} Poin Loyalitas',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.gold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Tombol Batalkan Booking (US-10: minimal 2 jam sebelumnya)
                      if (isUpcoming && booking.status == 'confirmed') ...[
                        OutlinedButton(
                          onPressed: booking.canCancel
                              ? () => _controller.cancelBooking(booking)
                              : () {
                                  Get.snackbar(
                                    'Pembatalan Ditolak',
                                    'Sesuai ketentuan, pembatalan hanya dapat dilakukan minimal 2 jam sebelum jadwal dimulai.',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: AppColors.ink,
                                    colorText: AppColors.paper,
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: booking.canCancel ? AppColors.danger : AppColors.inkSoft,
                            side: BorderSide(
                              color: booking.canCancel ? AppColors.danger : AppColors.hairline,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          child: Text(
                            booking.canCancel ? 'BATALKAN' : 'TIDAK DAPAT BATAL',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton(
                        onPressed: () => Get.toNamed('/booking-detail', arguments: booking),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text('TIKET', style: TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

