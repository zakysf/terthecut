import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

              // Alamat Lengkap
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
                    Text('ALAMAT RESMI', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 6),
                    Text(
                      branch.address,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.ink,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Wilayah: ${branch.city}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkSoft),
                    ),
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
