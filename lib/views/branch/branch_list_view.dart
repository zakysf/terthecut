import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../controllers/branch_controller.dart';
import 'branch_detail_view.dart';

class BranchListView extends StatefulWidget {
  final bool showBackButton;
  const BranchListView({super.key, this.showBackButton = true});

  @override
  State<BranchListView> createState() => _BranchListViewState();
}

class _BranchListViewState extends State<BranchListView> {
  final BranchController _controller = BranchController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.retrieveBranches();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('CABANG TER THE CUT'),
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Kolom Pencarian Cabang
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {});
                  _controller.searchBranches(val);
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama jalan atau cabang...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.inkSoft, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            _controller.searchBranches('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // =================================================================
            // FITUR LBS (MODUL 7): Banner & Tombol Deteksi Cabang Terdekat
            // =================================================================
            // Menggunakan ListenableBuilder agar UI kartu ini otomatis
            // merender ulang saat BranchController memanggil notifyListeners()
            // (misal ketika GPS mulai aktif, jarak terhitung, atau di-reset).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final isSorted = _controller.isSortedByDistance;
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSorted ? AppColors.accent : AppColors.hairline,
                        width: isSorted ? 1.2 : 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Ikon indikator lokasi GPS
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSorted
                                ? AppColors.accent.withValues(alpha: 0.15)
                                : AppColors.paper,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.my_location,
                            color: isSorted ? AppColors.accent : AppColors.inkSoft,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Judul & deskripsi panduan LBS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSorted
                                    ? 'Urutan: Cabang Terdekat'
                                    : 'Cari Cabang Terdekat',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isSorted
                                    ? 'Dihitung dari posisi GPS Anda'
                                    : 'Ketahui cabang terdekat dari lokasi Anda',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.inkSoft,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Indikator status: Loading, Tombol Reset, atau Tombol Cek GPS
                        if (_controller.isLocating)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          )
                        else if (isSorted)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(color: AppColors.danger, width: 0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onPressed: () => _controller.resetSort(),
                            child: Text(
                              'Reset',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger,
                              ),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            icon: const Icon(Icons.gps_fixed, size: 14),
                            label: const Text('Cek GPS'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: AppColors.ink,
                              foregroundColor: AppColors.paper,
                              textStyle: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onPressed: () async {
                              // Panggil controller untuk meminta izin & mencari cabang terdekat
                              await _controller.findNearestBranches();
                              if (!context.mounted) return;
                              // Jika terjadi kendala GPS / ditolak, beri tahu pengguna via SnackBar
                              if (_controller.locationError != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_controller.locationError!),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),

            // Daftar 11 Cabang
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.ink),
                    );
                  }

                  if (_controller.branches.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_off_outlined, size: 48, color: AppColors.inkSoft),
                          const SizedBox(height: 12),
                          Text(
                            'Cabang tidak ditemukan',
                            style: GoogleFonts.playfairDisplay(fontSize: 18, color: AppColors.ink),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _controller.branches.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final branch = _controller.branches[index];
                      return Card(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BranchDetailView(branch: branch),
                              ),
                            );
                          },
                        borderRadius: BorderRadius.circular(4),
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
                                      branch.name,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: branch.isOpenNow
                                          ? AppColors.success.withValues(alpha: 0.12)
                                          : AppColors.danger.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(
                                        color: branch.isOpenNow
                                            ? AppColors.success.withValues(alpha: 0.4)
                                            : AppColors.danger.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      branch.statusText,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: branch.isOpenNow ? AppColors.success : AppColors.danger,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.accent),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      branch.address,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.inkSoft,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: AppColors.inkSoft),
                                      const SizedBox(width: 6),
                                      Text(
                                        branch.formattedOperatingHours,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '2 Kapster Bertugas',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),

                              // Indikator Jarak LBS (Modul 7)
                              Builder(
                                builder: (context) {
                                  final distanceStr = _controller.getFormattedDistanceFor(branch.id);
                                  if (distanceStr == null) return const SizedBox.shrink();

                                  final isNearest = _controller.isSortedByDistance &&
                                      _controller.nearestBranch?.id == branch.id;

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isNearest
                                            ? AppColors.accent.withValues(alpha: 0.12)
                                            : AppColors.paper,
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color: isNearest ? AppColors.accent : AppColors.hairline,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isNearest ? Icons.stars : Icons.near_me,
                                            size: 14,
                                            color: isNearest ? AppColors.accent : AppColors.inkSoft,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            isNearest ? 'CABANG TERDEKAT • $distanceStr' : distanceStr,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: isNearest ? FontWeight.bold : FontWeight.w600,
                                              color: isNearest ? AppColors.accent : AppColors.ink,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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
}
