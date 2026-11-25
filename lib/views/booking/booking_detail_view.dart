import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/booking.dart';
import '../customer_root_view.dart';

class BookingDetailView extends StatelessWidget {
  final Booking? booking;

  const BookingDetailView({super.key, this.booking});

  @override
  Widget build(BuildContext context) {
    final Booking? bookingArg = booking;

    if (bookingArg == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('TIKET RESERVASI')),
        body: const Center(child: Text('Data reservasi tidak ditemukan.')),
      );
    }

    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(
          'TIKET DIGITAL',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Kartu Tiket Boarding Pass Editorial
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.hairline),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Tiket Elegan
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TER THE CUT',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.5,
                                  color: AppColors.paper,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  bookingArg.statusLabel.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: AppColors.paper,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'KODE RESERVASI',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                              color: AppColors.paper.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bookingArg.code,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4.0,
                              color: AppColors.paper,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tunjukkan kode ini kepada kasir saat tiba di lokasi',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.paper.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Garis Perforasi Tiket (Simulasi Robekan Kertas)
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Flex(
                                direction: Axis.horizontal,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  (constraints.constrainWidth() / 10).floor(),
                                  (_) => const SizedBox(
                                    width: 5,
                                    height: 1.5,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(color: AppColors.hairline),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                          ),
                        ),
                      ],
                    ),

                    // Detail Isi Reservasi
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailSection(
                            context: context,
                            title: 'LOKASI CABANG',
                            content: bookingArg.branchName,
                            subContent: bookingArg.branchAddress,
                            icon: Icons.store_outlined,
                          ),
                          const Divider(height: 24, color: AppColors.hairline),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDetailSection(
                                  context: context,
                                  title: 'KAPSTER',
                                  content: bookingArg.barberName,
                                  subContent: bookingArg.barberPref == 'auto'
                                      ? 'Sistem Auto-Assign'
                                      : 'Pilihan Pelanggan',
                                  icon: Icons.person_outline,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDetailSection(
                                  context: context,
                                  title: 'DURASI',
                                  content: '${bookingArg.durationHours} Jam Bulat',
                                  subContent: 'Slot waktu terkunci',
                                  icon: Icons.timer_outlined,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: AppColors.hairline),

                          _buildDetailSection(
                            context: context,
                            title: 'LAYANAN TERPILIH',
                            content: bookingArg.serviceName,
                            subContent: bookingArg.hairstyleName != null
                                ? 'Model: ${bookingArg.hairstyleName}'
                                : null,
                            icon: Icons.content_cut_outlined,
                          ),
                          const Divider(height: 24, color: AppColors.hairline),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildDetailSection(
                                  context: context,
                                  title: 'TANGGAL',
                                  content: bookingArg.formattedDate,
                                  icon: Icons.calendar_today_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDetailSection(
                                  context: context,
                                  title: 'JAM LAYANAN',
                                  content: bookingArg.formattedTimeRange,
                                  icon: Icons.access_time,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: AppColors.hairline),

                          // Biaya & Reward
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TOTAL ESTIMASI',
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currencyFormat.format(bookingArg.servicePrice),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.stars, color: AppColors.gold, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+${bookingArg.servicePoints} Poin Loyalitas',
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
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (bookingArg.status == 'cancelled') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cancel_outlined,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          bookingArg.cancelReason != null &&
                                  bookingArg.cancelReason!.isNotEmpty
                              ? 'Reservasi ini telah dibatalkan oleh admin (${bookingArg.cancelReason}).'
                              : 'Reservasi ini telah dibatalkan oleh admin.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerRootView()),
                  (route) => false,
                ),
                child: const Text('KEMBALI KE BERANDA'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required BuildContext context,
    required String title,
    required String content,
    String? subContent,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.accent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.playfairDisplay(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        if (subContent != null && subContent.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subContent,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkSoft),
          ),
        ],
      ],
    );
  }
}

