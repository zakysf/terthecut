import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../controllers/service_controller.dart';
import '../../controllers/booking_controller.dart';
import '../booking/booking_wizard_view.dart';

class ServiceCatalogView extends StatefulWidget {
  const ServiceCatalogView({super.key});

  @override
  State<ServiceCatalogView> createState() => _ServiceCatalogViewState();
}

class _ServiceCatalogViewState extends State<ServiceCatalogView> {
  final ServiceController _controller = ServiceController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.retrieveCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('KATALOG LAYANAN'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Kategori Filter Pills
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final categories = _controller.categories;
                final selectedId = _controller.selectedCategoryId;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _buildCategoryPill(
                        id: 'all',
                        label: 'Semua Layanan',
                        isSelected: selectedId == 'all',
                      ),
                      const SizedBox(width: 8),
                      ...categories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryPill(
                            id: cat.id,
                            label: cat.name,
                            isSelected: selectedId == cat.id,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),

            const Divider(color: AppColors.hairline, height: 1),

            // Daftar Layanan (18 Layanan)
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.ink),
                    );
                  }

                  final services = _controller.services;
                  if (services.isEmpty) {
                    return const Center(child: Text('Layanan belum tersedia.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: services.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final svc = services[index];
                      return Card(
                        child: InkWell(
                          onTap: () {
                            final bc = BookingController();
                            bc.initWizard(initialService: svc);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BookingWizardView()),
                            );
                          },
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
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                            if (svc.description != null && svc.description!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                svc.description!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.inkSoft,
                                  height: 1.3,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Badge Durasi Jam Bulat (1 Jam, 2 Jam, 3 Jam)
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.ink.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.timer_outlined, size: 12, color: AppColors.ink),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${svc.durationHours} JAM',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (svc.audience != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.paper,
                                          border: Border.all(color: AppColors.hairline),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          svc.audience!,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.inkSoft,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                // Badge Poin Reward
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '+${svc.points} POIN',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gold,
                                      letterSpacing: 0.8,
                                    ),
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
              },
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill({
    required String id,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _controller.filterByCategory(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.paper : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
