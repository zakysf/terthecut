import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../controllers/branch_controller.dart';

class BranchListView extends StatelessWidget {
  BranchListView({super.key});

  final BranchController _controller = Get.put(BranchController());
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('CABANG TER THE CUT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Kolom Pencarian Cabang
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => _controller.searchBranches(val),
                decoration: InputDecoration(
                  hintText: 'Cari nama jalan atau cabang...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.inkSoft, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _controller.searchBranches('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Daftar 11 Cabang
            Expanded(
              child: Obx(() {
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
                          Get.toNamed('/branch-detail', arguments: branch);
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
        ),
      ),
    );
  }
}
