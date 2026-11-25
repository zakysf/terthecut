import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/branch.dart';
import '../../controllers/branch_controller.dart';
import '../../controllers/booking_controller.dart';
import '../booking/booking_wizard_view.dart';

class BranchDetailView extends StatefulWidget {
  final Branch branch;

  const BranchDetailView({super.key, required this.branch});

  @override
  State<BranchDetailView> createState() => _BranchDetailViewState();
}

class _BranchDetailViewState extends State<BranchDetailView> {
  final BranchController _controller = BranchController();
  late final Branch branch;

  @override
  void initState() {
    super.initState();
    branch = widget.branch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadBarbersForBranch(branch.id);
    });
  }

  /// =========================================================================
  /// Helper Pembuka Navigasi Rute Google Maps (Modul 7 LBS):
  /// Menggunakan package url_launcher dengan mekanisme fallback 3-tahap:
  /// 1. Coba buka intent native Google Maps via URI 'geo:lat,lng'
  /// 2. Jika tidak ada aplikasi maps default, buka URL navigasi web Google Maps
  /// 3. Jika diblokir oleh OS, buka via web browser standar perangkat
  /// =========================================================================
  Future<void> _openGoogleMaps(
    BuildContext context,
    double lat,
    double lng,
    String branchName,
  ) async {
    final encodedName = Uri.encodeComponent('Ter The Cut $branchName');
    final mapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($encodedName)');

    // Tahap 1: Coba luncurkan aplikasi Native Maps
    try {
      if (await canLaunchUrl(geoUri)) {
        final ok = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    } catch (_) {}

    // Tahap 2: Coba luncurkan URL aplikasi Google Maps
    try {
      if (await canLaunchUrl(mapsUrl)) {
        final ok = await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    } catch (_) {}

    // Tahap 3: Fallback ke Browser bawaan jika native app tidak merespons
    try {
      final ok = await launchUrl(mapsUrl, mode: LaunchMode.platformDefault);
      if (ok) return;
    } catch (_) {}

    // Jika seluruh cara gagal, beri tahu pengguna
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tidak dapat membuka aplikasi peta di perangkat ini.'),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(branch.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Cabang
              Text(
                branch.name,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: branch.isOpenNow
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      branch.isOpenNow ? 'BUKA SEKARANG' : 'TUTUP',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: branch.isOpenNow ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    branch.formattedOperatingHours,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Kartu Alamat & Navigasi Lokasi (Modul 7 LBS)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.hairline),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ALAMAT LOKASI CABANG',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        // Badge Jarak Real-Time jika GPS sudah aktif
                        ListenableBuilder(
                          listenable: _controller,
                          builder: (context, _) {
                            final distanceStr = _controller.getFormattedDistanceFor(branch.id);
                            if (distanceStr == null) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.near_me, size: 12, color: AppColors.accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    distanceStr,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                branch.address,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.ink,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${branch.city}, Daerah Istimewa Yogyakarta',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (branch.latitude != null && branch.longitude != null) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.hairline),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.directions_outlined, size: 16),
                          label: const Text('Buka Rute di Google Maps'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            side: const BorderSide(color: AppColors.hairline, width: 1.2),
                            backgroundColor: AppColors.paper,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            textStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () => _openGoogleMaps(
                            context,
                            branch.latitude!,
                            branch.longitude!,
                            branch.name,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Bagian Kapster Bertugas di Cabang Ini
              Text(
                'KAPSTER BERTUGAS DI CABANG INI',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Setiap cabang memiliki 2 kapster profesional yang siap melayani Anda.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 14),

              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final barbers = _controller.selectedBranchBarbers;
                  if (barbers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator(color: AppColors.ink)),
                    );
                  }

                  return Column(
                  children: barbers.map((barber) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.ink,
                            child: Text(
                              barber.name.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.playfairDisplay(
                                color: AppColors.paper,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kapster ${barber.name}',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Spesialis Haircut & Texture Perm',
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
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Text(
                              'Aktif',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
              const SizedBox(height: 24),

              // Tombol Booking untuk Sprint 2
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: const Text('PESAN JADWAL DI CABANG INI'),
                onPressed: () {
                  final bc = BookingController();
                  bc.initWizard(initialBranch: branch);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookingWizardView()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
