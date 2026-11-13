import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../controllers/hairstyle_controller.dart';

class HairstyleListView extends StatelessWidget {
  HairstyleListView({super.key});

  final HairstyleController _controller = Get.put(HairstyleController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('INSPIRASI GAYA RAMBUT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (_controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.ink),
            );
          }

          final hairstyles = _controller.hairstyles;
          if (hairstyles.isEmpty) {
            return const Center(child: Text('Katalog gaya rambut kosong.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: hairstyles.length,
            itemBuilder: (context, index) {
              final item = hairstyles[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gambar Gaya Rambut
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (item.photoUrl != null)
                            Image.network(
                              item.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.hairline,
                                  child: const Icon(Icons.broken_image, color: AppColors.inkSoft),
                                );
                              },
                            )
                          else
                            Container(
                              color: AppColors.hairline,
                              child: const Icon(Icons.face, size: 40, color: AppColors.inkSoft),
                            ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.surface.withValues(alpha: 0.85),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 18,
                                icon: Icon(
                                  item.isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: item.isFavorite ? AppColors.accent : AppColors.ink,
                                ),
                                onPressed: () => _controller.toggleFavorite(item),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.inkSoft,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
